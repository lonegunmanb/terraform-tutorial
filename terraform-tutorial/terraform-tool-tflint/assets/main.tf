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

# 故意使用废弃的插值语法和错误的命名规范
resource "aws_s3_bucket" "MyBucket" {
  bucket        = "${var.bucket_name}"
  force_destroy = true

  tags = {
    Environment = "${var.environment}"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket" "logs" {
  bucket        = "${var.bucket_name}-logs"
  force_destroy = true
}

# variable 缺少 type 和 description
variable "bucket_name" {
  default = "my-demo-bucket"
}

variable "environment" {
  type    = string
  default = "dev"
}

# 未使用的变量
variable "unused_var" {
  type        = string
  default     = "not-used"
  description = "This variable is never referenced"
}

# 没有声明 type 的变量
variable "noType" {
  default     = "hello"
  description = "A variable without type declaration"
}

# output 缺少 description
output "bucket_id" {
  value = aws_s3_bucket.MyBucket.id
}

output "logs_bucket_id" {
  value       = aws_s3_bucket.logs.id
  description = "The ID of the logs bucket"
}
