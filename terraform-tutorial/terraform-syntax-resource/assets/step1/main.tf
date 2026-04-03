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
    sqs = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}

# ── 场景：静态网站托管 ──

# 1. 创建 S3 存储桶
resource "aws_s3_bucket" "website" {
  bucket = "my-tutorial-website"
}

# 2. 上传首页文件
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.website.id
  key          = "index.html"
  content      = <<-HTML
    <!DOCTYPE html>
    <html>
    <head><title>Terraform Tutorial</title></head>
    <body>
      <h1>Hello from Terraform!</h1>
      <p>This page was deployed by Terraform to S3.</p>
    </body>
    </html>
  HTML
  content_type = "text/html"
}

# 3. 上传错误页面
resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.website.id
  key          = "error.html"
  content      = <<-HTML
    <!DOCTYPE html>
    <html>
    <head><title>404 Not Found</title></head>
    <body><h1>Oops! Page not found.</h1></body>
    </html>
  HTML
  content_type = "text/html"
}

# 4. 创建通知队列（演示隐式依赖）
resource "aws_sqs_queue" "notifications" {
  name                       = "website-notifications"
  delay_seconds              = 0
  max_message_size           = 262144
  message_retention_seconds  = 86400
  visibility_timeout_seconds = 30
}

# ── 输出：引用资源属性 ──

output "bucket_id" {
  value       = aws_s3_bucket.website.id
  description = "S3 桶的 ID"
}

output "bucket_arn" {
  value       = aws_s3_bucket.website.arn
  description = "S3 桶的 ARN"
}

output "index_page_etag" {
  value       = aws_s3_object.index.etag
  description = "首页文件的 ETag（内容哈希）"
}

output "queue_url" {
  value       = aws_sqs_queue.notifications.url
  description = "SQS 队列的 URL"
}

output "queue_arn" {
  value       = aws_sqs_queue.notifications.arn
  description = "SQS 队列的 ARN"
}
