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

# 应用数据桶
resource "aws_s3_bucket" "demo" {
  bucket = "demo-app-bucket"
  tags = {
    Name      = "Demo Bucket"
    ManagedBy = "Terraform"
  }
}

# 状态存储桶 —— 后续步骤将把 Terraform 状态迁移到这个桶中
resource "aws_s3_bucket" "state" {
  bucket = "terraform-state-bucket"
  tags = {
    Name      = "Terraform State Bucket"
    ManagedBy = "Terraform"
  }
}

output "demo_bucket" {
  value = aws_s3_bucket.demo.bucket
}

output "state_bucket" {
  value = aws_s3_bucket.state.bucket
}
