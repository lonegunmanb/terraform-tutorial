terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS provider to use LocalStack endpoints
provider "aws" {
  region     = "us-east-1"
  access_key = "test"
  secret_key = "test"

  # Skip AWS credential validation since we're using LocalStack
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3       = "http://localhost:4566"
    iam      = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
    sts      = "http://localhost:4566"
    ec2      = "http://localhost:4566"
  }
}

# Example: Create an S3 bucket
resource "aws_s3_bucket" "tutorial" {
  bucket = "my-terraform-tutorial-bucket"

  tags = {
    Name        = "Tutorial Bucket"
    Environment = "Lab"
    ManagedBy   = "Terraform"
  }
}

output "bucket_name" {
  value       = aws_s3_bucket.tutorial.bucket
  description = "The name of the S3 bucket created by Terraform"
}
