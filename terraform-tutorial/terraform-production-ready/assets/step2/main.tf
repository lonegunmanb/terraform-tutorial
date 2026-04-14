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

module "storage" {
  source      = "./modules/storage"
  bucket_name = "${var.app_name}-${var.environment}-config"
}

module "queue" {
  source     = "./modules/queue"
  queue_name = "${var.app_name}-${var.environment}-notify"
}

module "database" {
  source     = "./modules/database"
  table_name = "${var.app_name}-${var.environment}-audit"
}

resource "aws_iam_policy" "app_reader" {
  name        = "${var.app_name}-${var.environment}-reader"
  description = "Allow application to read config from S3 and send SQS messages"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Resource = [module.storage.bucket_arn, "${module.storage.bucket_arn}/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["sqs:SendMessage", "sqs:GetQueueAttributes"]
        Resource = module.queue.queue_arn
      }
    ]
  })
}
