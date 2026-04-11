#!/bin/bash
exec > /tmp/background.log 2>&1
set -x

source /root/setup-common.sh

# ── 1. Seed workspace files ──
mkdir -p /root/workspace
cd /root/workspace

if [ ! -f main.tf ]; then
cat > main.tf <<'EOTF'
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

# 应用数据桶
resource "aws_s3_bucket" "app" {
  bucket = "${var.app_name}-${var.environment}-app"
  tags   = local.common_tags
}

# 日志桶
resource "aws_s3_bucket" "logs" {
  bucket = "${var.app_name}-${var.environment}-logs"
  tags   = local.common_tags
}

resource "aws_dynamodb_table" "sessions" {
  name         = "${var.app_name}-${var.environment}-sessions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "SessionID"

  attribute {
    name = "SessionID"
    type = "S"
  }

  tags = local.common_tags
}

locals {
  common_tags = {
    Environment = var.environment
    App         = var.app_name
    ManagedBy   = "Terraform"
  }
}
EOTF
fi

if [ ! -f variables.tf ]; then
cat > variables.tf <<'EOTF'
variable "environment" {
  type        = string
  default     = "dev"
  description = "部署环境"
}

variable "app_name" {
  type        = string
  default     = "myapp"
  description = "应用名称"
}
EOTF
fi

if [ ! -f outputs.tf ]; then
cat > outputs.tf <<'EOTF'
output "app_bucket" {
  value       = aws_s3_bucket.app.bucket
  description = "应用数据桶名称"
}

output "logs_bucket" {
  value       = aws_s3_bucket.logs.bucket
  description = "日志桶名称"
}

output "sessions_table" {
  value       = aws_dynamodb_table.sessions.name
  description = "会话表名称"
}
EOTF
fi

# ── 2. Install hcledit ──
HCLEDIT_VERSION="0.2.17"
curl -sSL "https://github.com/minamijoyo/hcledit/releases/download/v${HCLEDIT_VERSION}/hcledit_${HCLEDIT_VERSION}_linux_amd64.tar.gz" \
  | tar xz -C /usr/local/bin hcledit
chmod +x /usr/local/bin/hcledit

# ── 3. Install Terraform (for fmt comparison) ──
install_terraform

install_theia_plugin
finish_setup
