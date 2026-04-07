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

# ── 这两个桶已经被 Terraform 创建并管理 ──

resource "aws_s3_bucket" "app_data" {
  bucket = "refactor-app-data"
}

resource "aws_s3_bucket" "app_logs" {
  bucket = "refactor-app-logs"
}
