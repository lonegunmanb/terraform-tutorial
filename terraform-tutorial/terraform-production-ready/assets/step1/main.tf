# ──────────────────────────────────────────────────────────────────────────────
# step1/main.tf
# 反模式示例：所有资源挤在单个文件里
# 这个文件演示了"大模块"的典型问题：没有清晰边界、难以定位、牵一发动全身
# ──────────────────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
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
    iam      = "http://localhost:4566"
    sts      = "http://localhost:4566"
  }
}

# ── 变量 ──────────────────────────────────────────────────────────────────────

variable "environment" {
  type    = string
  default = "dev"
}

variable "app_name" {
  type    = string
  default = "config-center"
}

# ── S3 存储桶（配置文件存储）─────────────────────────────────────────────────

resource "aws_s3_bucket" "config" {
  bucket = "${var.app_name}-${var.environment}-config"
}

resource "aws_s3_bucket_versioning" "config" {
  bucket = aws_s3_bucket.config.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ── SQS 队列（变更通知）──────────────────────────────────────────────────────

resource "aws_sqs_queue" "dead_letter" {
  name = "${var.app_name}-${var.environment}-notify-dlq"
}

resource "aws_sqs_queue" "notifications" {
  name                       = "${var.app_name}-${var.environment}-notify"
  message_retention_seconds  = 86400
  visibility_timeout_seconds = 30
}

resource "aws_sqs_queue_redrive_policy" "notifications" {
  queue_url = aws_sqs_queue.notifications.id
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter.arn
    maxReceiveCount     = 5
  })
}

# ── DynamoDB 表（变更审计日志）───────────────────────────────────────────────

resource "aws_dynamodb_table" "audit_log" {
  name         = "${var.app_name}-${var.environment}-audit"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"
  range_key    = "timestamp"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }
}

# ── IAM 策略（应用读取权限）──────────────────────────────────────────────────

resource "aws_iam_policy" "app_reader" {
  name        = "${var.app_name}-${var.environment}-reader"
  description = "Allow application to read config from S3 and send SQS messages"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Resource = [aws_s3_bucket.config.arn, "${aws_s3_bucket.config.arn}/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["sqs:SendMessage", "sqs:GetQueueAttributes"]
        Resource = aws_sqs_queue.notifications.arn
      }
    ]
  })
}

# ── 输出 ──────────────────────────────────────────────────────────────────────

output "config_bucket_name" {
  value = aws_s3_bucket.config.bucket
}

output "notification_queue_url" {
  value = aws_sqs_queue.notifications.url
}

output "audit_table_name" {
  value = aws_dynamodb_table.audit_log.name
}

output "app_policy_arn" {
  value = aws_iam_policy.app_reader.arn
}
