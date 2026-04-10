#!/bin/bash
exec > /tmp/background.log 2>&1
set -x

source /root/setup-common.sh

# ── 1. Seed workspace files ──
mkdir -p /root/workspace
cd /root/workspace

if [ ! -f docker-compose.yml ]; then
cat > docker-compose.yml <<'EOF'
services:
  localstack:
    image: localstack/localstack:3
    ports:
      - "4566:4566"
    environment:
      - SERVICES=s3,dynamodb
      - DEFAULT_REGION=us-east-1
      - EAGER_SERVICE_LOADING=1
    deploy:
      resources:
        limits:
          memory: 1536M
EOF
fi

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

variable "app_name" {
  type        = string
  default     = "myapp"
  description = "应用名称"
}

locals {
  env = terraform.workspace

  common_tags = {
    Environment = local.env
    App         = var.app_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket" "data" {
  bucket = "${var.app_name}-${local.env}-data"
  tags   = local.common_tags
}

resource "aws_dynamodb_table" "sessions" {
  name         = "${var.app_name}-${local.env}-sessions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "SessionID"

  attribute {
    name = "SessionID"
    type = "S"
  }

  tags = local.common_tags
}

output "workspace_name" {
  value = terraform.workspace
}

output "bucket_name" {
  value = aws_s3_bucket.data.bucket
}

output "table_name" {
  value = aws_dynamodb_table.sessions.name
}
EOTF
fi

# ── 2. Install tooling ──
install_terraform
install_awscli
start_localstack

# ── 3. Initialize providers (do NOT apply — students run apply themselves) ──
terraform init

install_theia_plugin
finish_setup
