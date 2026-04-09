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

resource "aws_s3_bucket" "app" {
  bucket = "${var.app_name}-${var.environment}-app"
  tags = {
    Environment = var.environment
    App         = var.app_name
    ManagedBy   = "Terraform"
  }
}

output "bucket_name" {
  value = aws_s3_bucket.app.bucket
}
