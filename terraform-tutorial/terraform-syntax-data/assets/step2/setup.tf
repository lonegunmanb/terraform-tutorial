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
    sqs      = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
    sts      = "http://localhost:4566"
  }
}

# ══════════════════════════════════════════
# setup.tf — 先创建一些"已有"资源
# 模拟在 data 查询之前就存在的基础设施
# ══════════════════════════════════════════

resource "aws_s3_bucket" "shared_config" {
  bucket = "shared-config-bucket"
}

resource "aws_s3_object" "app_config" {
  bucket       = aws_s3_bucket.shared_config.id
  key          = "app/config.json"
  content      = jsonencode({
    db_host   = "db.internal.example.com"
    db_port   = 5432
    cache     = "redis.internal.example.com"
    log_level = "info"
  })
  content_type = "application/json"
}

resource "aws_sqs_queue" "shared_events" {
  name                       = "shared-events-queue"
  message_retention_seconds  = 345600
  visibility_timeout_seconds = 60
}
