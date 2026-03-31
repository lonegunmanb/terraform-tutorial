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

  endpoints {
    s3  = "http://localhost:4566"
    iam = "http://localhost:4566"
    ec2 = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}

# ❌ Issue 1: Variable without description
variable "BucketName" {
  type    = string
  default = "my-lint-test-bucket"
}

# ❌ Issue 2: Non-snake_case naming (PascalCase variable above)

# ❌ Issue 3: Unused variable
variable "unused_region" {
  type        = string
  default     = "us-west-2"
  description = "This variable is never referenced anywhere"
}

resource "aws_s3_bucket" "example" {
  bucket = var.BucketName

  tags = {
    Name = "Lint Test Bucket"
  }
}

# ❌ Issue 4: Referencing a deprecated attribute
output "bucket_domain" {
  value       = aws_s3_bucket.example.bucket_domain_name
  description = "The domain name of the bucket (deprecated attribute)"
}
