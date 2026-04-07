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

# ── 这些资源目前散落在根模块，需要提取到子模块 ──

resource "aws_s3_bucket" "user_uploads" {
  bucket = "modular-user-uploads"
  tags = {
    Purpose = "uploads"
  }
}

resource "aws_s3_bucket" "user_backups" {
  bucket = "modular-user-backups"
  tags = {
    Purpose = "backups"
  }
}
