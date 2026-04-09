terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
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
    iam = "http://localhost:4566"
    s3  = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}

# ── Layer 0: IAM Role ──
# 真实 AWS 中，IAM 角色创建后需要数秒到数十秒才能在所有区域生效（最终一致性）。
resource "aws_iam_role" "app" {
  name = "app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { Name = "app-role" }
}

# ── Layer 1: time_sleep 模拟 IAM 全局传播延迟 ──
# 参考: https://github.com/hashicorp/terraform-provider-aws/issues/29392
# 如果在角色未完全传播时就在策略中引用其 ARN，AWS API 会返回：
#   "Invalid policy document. Please check the policy syntax and ensure that Principals are valid."
# time_sleep 确保等待传播完成后再继续；同时也保证 destroy 时先删除引用方再删除角色。
resource "time_sleep" "iam_propagation" {
  create_duration = "10s"

  depends_on = [aws_iam_role.app]

  triggers = {
    role_arn = aws_iam_role.app.arn
  }
}

# ── Layer 0（独立）: S3 Bucket ──
resource "aws_s3_bucket" "data" {
  bucket = "demo-data-bucket"
  tags   = { Name = "data-bucket" }
}

# ── Layer 2: Bucket Policy（通过 time_sleep 获取已传播的 role ARN）──
# 依赖链：aws_iam_role.app → time_sleep → aws_s3_bucket_policy.access
# 销毁时 Terraform 按逆序操作：先删 policy，再删 time_sleep，最后删 role。
resource "aws_s3_bucket_policy" "access" {
  bucket = aws_s3_bucket.data.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowAppRole"
      Effect    = "Allow"
      Principal = { AWS = time_sleep.iam_propagation.triggers["role_arn"] }
      Action    = ["s3:GetObject", "s3:ListBucket"]
      Resource  = [
        aws_s3_bucket.data.arn,
        "${aws_s3_bucket.data.arn}/*"
      ]
    }]
  })
}
