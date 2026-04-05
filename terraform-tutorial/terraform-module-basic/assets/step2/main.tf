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

# 通过 module 块调用子模块，传入不同参数创建不同的桶
module "data_bucket" {
  source      = "./modules/s3-bucket"
  bucket_name = "my-app-data"
  tags = {
    Environment = "production"
    Purpose     = "data-storage"
  }
}

module "logs_bucket" {
  source      = "./modules/s3-bucket"
  bucket_name = "my-app-logs"
  tags = {
    Environment = "production"
    Purpose     = "logging"
  }
}

output "data_bucket_id" {
  value       = module.data_bucket.bucket_id
  description = "数据桶的 ID"
}

output "data_bucket_arn" {
  value       = module.data_bucket.bucket_arn
  description = "数据桶的 ARN"
}

output "logs_bucket_id" {
  value       = module.logs_bucket.bucket_id
  description = "日志桶的 ID"
}

output "logs_bucket_arn" {
  value       = module.logs_bucket.bucket_arn
  description = "日志桶的 ARN"
}
