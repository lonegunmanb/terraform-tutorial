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

resource "aws_s3_bucket" "app" {
  bucket = "state-demo-app"
  tags = {
    Name        = "Application Bucket"
    Environment = "production"
  }
}

resource "aws_s3_bucket" "logs" {
  bucket = "state-demo-logs"
  tags = {
    Name        = "Logs Bucket"
    Environment = "production"
  }
}

resource "aws_s3_bucket" "data" {
  bucket = "state-demo-data"
  tags = {
    Name        = "Data Bucket"
    Environment = "staging"
  }
}

resource "aws_dynamodb_table" "locks" {
  name         = "state-demo-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Lock Table"
    Environment = "production"
  }
}
