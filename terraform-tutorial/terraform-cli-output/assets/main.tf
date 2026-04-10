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
    s3       = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
    sts      = "http://localhost:4566"
  }
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "部署环境"
}

variable "app_name" {
  type        = string
  default     = "myapp"
  description = "应用名称"
}

locals {
  common_tags = {
    Environment = var.environment
    App         = var.app_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket" "app" {
  bucket = "${var.app_name}-${var.environment}-app"
  tags   = local.common_tags
}

resource "aws_s3_bucket" "logs" {
  bucket = "${var.app_name}-${var.environment}-logs"
  tags   = local.common_tags
}

resource "aws_dynamodb_table" "sessions" {
  name         = "${var.app_name}-${var.environment}-sessions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "SessionID"

  attribute {
    name = "SessionID"
    type = "S"
  }

  tags = local.common_tags
}

# ── string output ──
output "app_bucket" {
  description = "应用数据桶名称"
  value       = aws_s3_bucket.app.bucket
}

output "logs_bucket" {
  description = "日志桶名称"
  value       = aws_s3_bucket.logs.bucket
}

output "sessions_table" {
  description = "会话表名称"
  value       = aws_dynamodb_table.sessions.name
}

# ── sensitive output ──
output "db_connection" {
  description = "数据库连接信息（敏感）"
  sensitive   = true
  value       = "dynamodb://localhost:4566/${aws_dynamodb_table.sessions.name}"
}

# ── list output ──
output "all_bucket_names" {
  description = "所有 S3 桶名列表"
  value       = [aws_s3_bucket.app.bucket, aws_s3_bucket.logs.bucket]
}

# ── map output ──
output "resource_summary" {
  description = "资源摘要"
  value = {
    app_bucket     = aws_s3_bucket.app.bucket
    logs_bucket    = aws_s3_bucket.logs.bucket
    sessions_table = aws_dynamodb_table.sessions.name
    environment    = var.environment
  }
}
