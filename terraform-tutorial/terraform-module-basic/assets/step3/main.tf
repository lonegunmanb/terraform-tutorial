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

# ── 调用子模块创建 S3 桶 ──

module "data_bucket" {
  source      = "./modules/s3-bucket"
  bucket_name = "my-app-data"
  tags = {
    Purpose = "data"
  }
}

module "logs_bucket" {
  source      = "./modules/s3-bucket"
  bucket_name = "my-app-logs"
  tags = {
    Purpose = "logs"
  }
}

output "data_bucket_id" {
  value = module.data_bucket.bucket_id
}

output "data_bucket_arn" {
  value = module.data_bucket.bucket_arn
}

output "logs_bucket_id" {
  value = module.logs_bucket.bucket_id
}
