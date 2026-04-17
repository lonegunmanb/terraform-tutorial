terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

locals {
  app_name = "${var.app_name}-${random_string.suffix.result}"
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
    s3             = "http://localhost:4566"
    sqs            = "http://localhost:4566"
    sns            = "http://localhost:4566"
    dynamodb       = "http://localhost:4566"
    iam            = "http://localhost:4566"
    sts            = "http://localhost:4566"
    secretsmanager = "http://localhost:4566"
    ssm            = "http://localhost:4566"
    cloudwatchlogs = "http://localhost:4566"
    ec2            = "http://localhost:4566"
    elbv2          = "http://localhost:4566"
  }
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "app_name" {
  type    = string
  default = "webapp"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

# ── 网络层（已提取为模块）───────────────────────────────────────────────────
module "networking" {
  source = "./modules/networking"

  app_name    = local.app_name
  environment = var.environment
  vpc_cidr    = var.vpc_cidr
}

# ── Web 层（已提取为模块）─────────────────────────────────────────────────
module "web" {
  source = "./modules/web"

  app_name                  = local.app_name
  environment               = var.environment
  vpc_id                    = module.networking.vpc_id
  public_subnet_ids         = module.networking.public_subnet_ids
  private_subnet_ids        = module.networking.private_subnet_ids
  app_instance_profile_name = aws_iam_instance_profile.app.name
}

# ══════════════════════════════════════════════════════════════════════════════
# 数据层（待提取）
# ══════════════════════════════════════════════════════════════════════════════

resource "aws_dynamodb_table" "users" {
  name         = "${local.app_name}-${var.environment}-users"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "UserId"
  range_key    = "CreatedAt"

  attribute {
    name = "UserId"
    type = "S"
  }

  attribute {
    name = "CreatedAt"
    type = "S"
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# 存储层（待提取）
# ══════════════════════════════════════════════════════════════════════════════

resource "aws_s3_bucket" "static_assets" {
  bucket = "${local.app_name}-${var.environment}-static"
}

resource "aws_s3_bucket_versioning" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket" "backups" {
  bucket = "${local.app_name}-${var.environment}-backups"
}

resource "aws_s3_bucket_versioning" "backups" {
  bucket = aws_s3_bucket.backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id
  rule {
    id     = "expire-old-backups"
    status = "Enabled"
    expiration {
      days = 90
    }
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# 安全与配置（待提取）
# ══════════════════════════════════════════════════════════════════════════════

resource "aws_secretsmanager_secret" "db_credentials" {
  name = "${local.app_name}/${var.environment}/db-credentials"
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = "app_user"
    password = "change-me-in-production"
    host     = "db.internal"
    port     = 5432
  })
}

resource "aws_ssm_parameter" "app_config" {
  name  = "/${local.app_name}/${var.environment}/config"
  type  = "String"
  value = jsonencode({
    log_level     = "info"
    cache_ttl     = 300
    feature_flags = { new_dashboard = true }
  })
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/${local.app_name}/${var.environment}/app"
  retention_in_days = 30
}

resource "aws_iam_role" "app" {
  name = "${local.app_name}-${var.environment}-app-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "app" {
  name = "${local.app_name}-${var.environment}-app-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = ["${aws_s3_bucket.static_assets.arn}/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:Query"]
        Resource = aws_dynamodb_table.users.arn
      },
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = aws_secretsmanager_secret.db_credentials.arn
      },
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter"]
        Resource = aws_ssm_parameter.app_config.arn
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "${aws_cloudwatch_log_group.app.arn}:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "app" {
  role       = aws_iam_role.app.name
  policy_arn = aws_iam_policy.app.arn
}

resource "aws_iam_instance_profile" "app" {
  name = "${local.app_name}-${var.environment}-app-profile"
  role = aws_iam_role.app.name
}

# ══════════════════════════════════════════════════════════════════════════════
# 输出
# ══════════════════════════════════════════════════════════════════════════════

output "vpc_id" {
  value = module.networking.vpc_id
}

output "alb_dns_name" {
  value = module.web.alb_dns_name
}

output "static_bucket" {
  value = aws_s3_bucket.static_assets.bucket
}

output "backup_bucket" {
  value = aws_s3_bucket.backups.bucket
}

output "users_table" {
  value = aws_dynamodb_table.users.name
}

output "app_role_arn" {
  value = aws_iam_role.app.arn
}
