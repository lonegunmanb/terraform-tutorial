#!/bin/bash
exec > /tmp/background.log 2>&1
set -x

source /root/setup-common.sh

# ── 1. Ensure workspace directories exist ──
mkdir -p /root/workspace/step1
mkdir -p /root/workspace/step2

# ── 2. Seed workspace files (fallback if assets copy fails) ──

if [ ! -f /root/workspace/step1/main.tf ]; then
cat > /root/workspace/step1/main.tf <<'EOTF'
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = "test"
  secret_key = "test"

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2 = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}

# ── 输入变量 ──

variable "environment" {
  type    = string
  default = "dev"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

# ── 局部值 ──

locals {
  project     = "myapp"
  environment = var.environment
  name_prefix = "${local.project}-${local.environment}"

  common_tags = {
    Project     = local.project
    Environment = local.environment
    ManagedBy   = "terraform"
  }
}

# ── 网络层 ──

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 1)
  availability_zone = "us-east-1a"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-a"
  })
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 2)
  availability_zone = "us-east-1b"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-b"
  })
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 10)
  availability_zone = "us-east-1a"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-igw"
  })
}

# ── NAT Gateway（regional 模式，双可用区） ──

resource "aws_eip" "nat_a" {
  domain = "vpc"
  tags   = merge(local.common_tags, { Name = "${local.name_prefix}-nat-eip-a" })
}

resource "aws_eip" "nat_b" {
  domain = "vpc"
  tags   = merge(local.common_tags, { Name = "${local.name_prefix}-nat-eip-b" })
}

resource "aws_nat_gateway" "main" {
  availability_mode = "regional"
  vpc_id            = aws_vpc.main.id

  availability_zone_address {
    allocation_ids    = [aws_eip.nat_a.id]
    availability_zone = "us-east-1a"
  }

  availability_zone_address {
    allocation_ids    = [aws_eip.nat_b.id]
    availability_zone = "us-east-1b"
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nat"
  })

  lifecycle {
    ignore_changes = [tags]
  }

  depends_on = [aws_internet_gateway.main]
}

# ── 安全组 ──

resource "aws_security_group" "web" {
  name        = "${local.name_prefix}-web-sg"
  description = "Allow web and SSH traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "SSH from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

# ── 计算实例 ──

resource "aws_instance" "web" {
  ami                    = "ami-0c55b159cbfafe1f0"
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.web.id]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-web"
  })
}

# ── 输出值 ──

output "vpc_id" {
  value = aws_vpc.main.id
}

output "nat_gateway_id" {
  value = aws_nat_gateway.main.id
}

output "instance_type" {
  value = var.instance_type
}

output "name_prefix" {
  value = local.name_prefix
}

output "environment" {
  value = local.environment
}
EOTF
fi

if [ ! -f /root/workspace/step2/main.tf ]; then
cat > /root/workspace/step2/main.tf <<'EOTF'
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = "test"
  secret_key = "test"

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    s3  = "http://localhost:4566"
    sqs = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}

# ── 原始配置 ──

variable "app_name" {
  type    = string
  default = "webapp"
}

variable "instance_count" {
  type    = number
  default = 1
}

locals {
  region      = "us-east-1"
  environment = "dev"
  prefix      = "${var.app_name}-${local.environment}"
}

resource "aws_sqs_queue" "tasks" {
  name                       = "${local.prefix}-tasks"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 345600

  tags = {
    App         = var.app_name
    Environment = local.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket" "artifacts" {
  bucket = "${local.prefix}-artifacts"

  tags = {
    App         = var.app_name
    Environment = local.environment
  }
}

# ── 输出值（测试会依赖这些输出） ──

output "queue_name" {
  value = aws_sqs_queue.tasks.name
}

output "queue_visibility_timeout" {
  value = aws_sqs_queue.tasks.visibility_timeout_seconds
}

output "bucket_id" {
  value = aws_s3_bucket.artifacts.id
}

output "prefix" {
  value = local.prefix
}

output "environment" {
  value = local.environment
}

output "instance_count" {
  value = var.instance_count
}

# ══════════════════════════════════════════════════════
# 习题：请创建重载文件完成以下要求
# ══════════════════════════════════════════════════════
#
# 请创建一个名为 override.tf 的重载文件，实现以下覆盖：
#
# 第 1 题：将 variable "instance_count" 的默认值改为 3
#
# 第 2 题：将 locals 中的 environment 改为 "prod"
#
# 第 3 题：将 aws_sqs_queue "tasks" 的 visibility_timeout_seconds 改为 60
#
# 第 4 题：将 aws_s3_bucket "artifacts" 的 tags 改为只包含
#          { CostCenter = "engineering" }
#
# 提示：所有修改写在同一个 override.tf 文件中即可。
# 完成后运行 terraform test 验证答案。
EOTF
fi

if [ ! -f /root/workspace/step2/override_test.tftest.hcl ]; then
cat > /root/workspace/step2/override_test.tftest.hcl <<'EOTF'
run "test_instance_count_overridden" {
  command = plan

  assert {
    condition     = var.instance_count == 3
    error_message = "第 1 题：instance_count 应被重载为 3，当前值为 ${var.instance_count}"
  }
}

run "test_environment_overridden" {
  command = apply

  assert {
    condition     = output.environment == "prod"
    error_message = "第 2 题：environment 应被重载为 \"prod\"，当前值为 \"${output.environment}\""
  }
}

run "test_prefix_reflects_override" {
  command = apply

  assert {
    condition     = output.prefix == "webapp-prod"
    error_message = "第 2 题（验证）：prefix 应为 \"webapp-prod\"，当前值为 \"${output.prefix}\""
  }
}

run "test_queue_visibility_timeout" {
  command = apply

  assert {
    condition     = output.queue_visibility_timeout == 60
    error_message = "第 3 题：SQS 队列的 visibility_timeout_seconds 应被重载为 60，当前值为 ${output.queue_visibility_timeout}"
  }
}

run "test_queue_name_uses_prod" {
  command = apply

  assert {
    condition     = output.queue_name == "webapp-prod-tasks"
    error_message = "综合验证：队列名称应为 \"webapp-prod-tasks\"，当前值为 \"${output.queue_name}\""
  }
}

run "test_bucket_uses_prod_prefix" {
  command = apply

  assert {
    condition     = output.bucket_id == "webapp-prod-artifacts"
    error_message = "综合验证：桶 ID 应为 \"webapp-prod-artifacts\"，当前值为 \"${output.bucket_id}\""
  }
}
EOTF
fi

if [ ! -f /root/workspace/docker-compose.yml ]; then
cat > /root/workspace/docker-compose.yml <<'EODC'
services:
  localstack:
    image: localstack/localstack:3
    ports:
      - "4566:4566"
    environment:
      - SERVICES=s3,sqs
      - DEFAULT_REGION=us-east-1
      - EAGER_SERVICE_LOADING=1
    deploy:
      resources:
        limits:
          memory: 1536M
EODC
fi

# ── 3. Install tools ──
install_terraform
install_awscli

# ── 4. Start LocalStack ──
start_localstack

# ── 5. Pre-init both steps ──
cd /root/workspace/step1
terraform init

cd /root/workspace/step2
terraform init

# ── 6. Signal completion ──
finish_setup
