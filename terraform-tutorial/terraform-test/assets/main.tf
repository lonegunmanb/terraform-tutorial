terraform {
  required_version = ">= 1.6"
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

resource "aws_s3_bucket" "app" {
  bucket = "${var.app_name}-${var.environment}-app-${var.suffix}"
  tags   = local.common_tags
}

resource "aws_s3_bucket" "logs" {
  bucket = "${var.app_name}-${var.environment}-logs-${var.suffix}"
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

locals {
  common_tags = {
    Environment = var.environment
    App         = var.app_name
    ManagedBy   = "Terraform"
  }
}
