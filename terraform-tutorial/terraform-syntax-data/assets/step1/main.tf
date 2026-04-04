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

# ── 数据源：查询环境信息 ──

# 查询当前 AWS 账号信息（在 LocalStack 中返回模拟值）
data "aws_caller_identity" "current" {}

# 查询当前区域
data "aws_region" "current" {}

# ── 资源：使用数据源的信息 ──

# 用账号 ID 和区域构建桶名，确保全局唯一
resource "aws_s3_bucket" "app_data" {
  bucket = "app-data-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
}

# 创建一个带元数据的对象，记录谁创建了它
resource "aws_s3_object" "metadata" {
  bucket  = aws_s3_bucket.app_data.id
  key     = "metadata.json"
  content = jsonencode({
    account_id = data.aws_caller_identity.current.account_id
    region     = data.aws_region.current.name
    arn        = data.aws_caller_identity.current.arn
    created_by = "terraform"
  })
  content_type = "application/json"
}

# ── 输出 ──

output "account_id" {
  value       = data.aws_caller_identity.current.account_id
  description = "当前 AWS 账号 ID"
}

output "caller_arn" {
  value       = data.aws_caller_identity.current.arn
  description = "当前调用者 ARN"
}

output "region" {
  value       = data.aws_region.current.name
  description = "当前区域"
}

output "bucket_name" {
  value       = aws_s3_bucket.app_data.id
  description = "桶名（包含账号 ID 和区域）"
}
