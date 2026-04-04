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
