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
