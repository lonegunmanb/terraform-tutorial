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
    iam      = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
    sts      = "http://localhost:4566"
  }
}

# S3 bucket — students will inspect and manipulate its state
resource "aws_s3_bucket" "data" {
  bucket = "my-app-data-bucket"

  tags = {
    Name        = "Data Bucket"
    Environment = "Lab"
    ManagedBy   = "Terraform"
  }
}

# S3 bucket for logs — used to practice state mv / state rm
resource "aws_s3_bucket" "logs" {
  bucket = "my-app-logs-bucket"

  tags = {
    Name        = "Logs Bucket"
    Environment = "Lab"
    ManagedBy   = "Terraform"
  }
}

# DynamoDB table — another resource to explore in state
resource "aws_dynamodb_table" "locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name      = "Terraform Lock Table"
    ManagedBy = "Terraform"
  }
}

output "data_bucket" {
  value = aws_s3_bucket.data.bucket
}

output "logs_bucket" {
  value = aws_s3_bucket.logs.bucket
}

output "lock_table" {
  value = aws_dynamodb_table.locks.name
}
