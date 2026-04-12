#!/bin/bash
exec > /tmp/background.log 2>&1
set -x

source /root/setup-common.sh

# ── 1. Create a messy Terraform module for avmfix to fix ──
git config --global user.email "lab@example.com"
git config --global user.name "Lab User"
git config --global init.defaultBranch main
mkdir -p /root/workspace
cd /root/workspace

# main.tf — intentionally messy: wrong attribute order, output in wrong file, etc.
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

# resource 块属性顺序故意打乱
resource "aws_s3_bucket" "logs" {
  tags          = local.common_tags
  bucket        = "${var.app_name}-logs"
  force_destroy = true
}

resource "aws_s3_bucket" "app" {
  depends_on    = [aws_s3_bucket.logs]
  tags          = local.common_tags
  force_destroy = var.force_destroy
  bucket        = "${var.app_name}-app"
}

resource "aws_dynamodb_table" "sessions" {
  tags         = local.common_tags
  hash_key     = "SessionID"
  name         = "${var.app_name}-sessions"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "SessionID"
    type = "S"
  }
}

locals {
  # locals 故意不按字母序
  environment = var.environment
  common_tags = {
    ManagedBy   = "Terraform"
    Environment = local.environment
    App         = var.app_name
  }
  app_prefix = "${var.app_name}-${var.environment}"
}

# output 故意放在 main.tf 而非 outputs.tf
output "sessions_table" {
  value       = aws_dynamodb_table.sessions.name
  description = "DynamoDB 会话表名称"
}

output "app_bucket" {
  description = "应用数据桶"
  value       = aws_s3_bucket.app.bucket
}

output "logs_bucket" {
  value       = aws_s3_bucket.logs.bucket
  description = "日志桶"
}

# variable 故意放在 main.tf 而非 variables.tf，属性顺序也打乱
variable "force_destroy" {
  default     = false
  description = "是否强制删除桶内对象"
  type        = bool
  nullable    = true
  sensitive   = false
}
EOTF

# variables.tf — 变量属性顺序打乱
cat > variables.tf <<'EOTF'
variable "app_name" {
  default     = "myapp"
  description = "应用名称"
  type        = string
}

variable "environment" {
  description = "部署环境"
  default     = "dev"
  type        = string
}
EOTF

# ── 2. Install tooling ──
install_terraform

# Install Go
echo "安装 Go..."
if ! command -v go &>/dev/null; then
  curl -sSL "https://go.dev/dl/go1.23.8.linux-amd64.tar.gz" -o /tmp/go.tar.gz
  tar xzf /tmp/go.tar.gz -C /usr/local
  rm -f /tmp/go.tar.gz
fi
export GOPATH=/root/go
export PATH=/usr/local/go/bin:/root/go/bin:$PATH
echo 'export GOPATH=/root/go' >> /root/.bashrc
echo 'export PATH=/usr/local/go/bin:/root/go/bin:$PATH' >> /root/.bashrc
go version

# Install avmfix
echo "安装 avmfix..."
go install github.com/lonegunmanb/avmfix@latest
avmfix -h >/dev/null 2>&1 && echo "avmfix 安装成功" || echo "avmfix 安装失败"

# Initialize terraform (for schema)
cd /root/workspace
terraform init

install_theia_plugin
finish_setup
