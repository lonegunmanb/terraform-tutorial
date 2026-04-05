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
    sts = "http://localhost:4566"
  }
}

# ── 模块传参示例 ──

variable "project" {
  type    = string
  default = "myapp"
}

variable "environment" {
  type    = string
  default = "dev"
}

# 将根模块的变量组合后传入子模块
module "data_bucket" {
  source      = "../modules/s3-bucket"
  bucket_name = "${var.project}-${var.environment}-data"
  tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "data"
  }
}

module "logs_bucket" {
  source      = "../modules/s3-bucket"
  bucket_name = "${var.project}-${var.environment}-logs"
  tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "logs"
  }
}

# ── 输出引用 ──

output "data_bucket_id" {
  value       = module.data_bucket.bucket_id
  description = "数据桶 ID"
}

output "data_bucket_arn" {
  value       = module.data_bucket.bucket_arn
  description = "数据桶 ARN"
}

output "logs_bucket_id" {
  value       = module.logs_bucket.bucket_id
  description = "日志桶 ID"
}

# 将模块输出传给另一个资源或输出
output "all_bucket_ids" {
  value = [
    module.data_bucket.bucket_id,
    module.logs_bucket.bucket_id,
  ]
  description = "所有桶的 ID 列表"
}
