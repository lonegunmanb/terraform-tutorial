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

variable "app_name" {
  type        = string
  default     = "myapp"
  description = "应用名称"
}

locals {
  env = terraform.workspace

  common_tags = {
    Environment = local.env
    App         = var.app_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket" "data" {
  bucket = "${var.app_name}-${local.env}-data"
  tags   = local.common_tags
}

resource "aws_dynamodb_table" "sessions" {
  name         = "${var.app_name}-${local.env}-sessions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "SessionID"

  attribute {
    name = "SessionID"
    type = "S"
  }

  tags = local.common_tags
}

output "workspace_name" {
  value = terraform.workspace
}

output "bucket_name" {
  value = aws_s3_bucket.data.bucket
}

output "table_name" {
  value = aws_dynamodb_table.sessions.name
}
