#!/bin/bash
exec > /tmp/background.log 2>&1
set -x

source /root/setup-common.sh

# ── 1. Seed workspace files (fallback if assets copy fails) ──
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
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "部署环境（dev / staging / prod）"
}

variable "app_name" {
  type        = string
  default     = "my-app"
  description = "应用名称"
}

locals {
  name_prefix = "${var.app_name}-${var.environment}"
  common_tags = {
    Environment = var.environment
    App         = var.app_name
  }
}

resource "null_resource" "setup" {
  triggers = {
    name = local.name_prefix
  }
}

resource "null_resource" "deploy" {
  depends_on = [null_resource.setup]

  triggers = {
    env = var.environment
  }
}

output "name_prefix" {
  value       = local.name_prefix
  description = "资源名称前缀"
}
EOTF
fi

# ── 2. Create local module for terraform get demo ──
mkdir -p /root/workspace/modules/greet
if [ ! -f /root/workspace/modules/greet/main.tf ]; then
cat > /root/workspace/modules/greet/main.tf <<'EOTF'
variable "name" {
  type    = string
  default = "World"
}

output "message" {
  value = "Hello, ${var.name}!"
}
EOTF
fi

# ── 3. Seed unformatted file for fmt demo ──
cat > /root/workspace/unformatted.tf <<'EOF'
# 格式化演示文件 —— 运行 terraform fmt 来修复此文件的缩进风格
variable "region" {
type    = string
default =  "us-east-1"
description = "Region"
}
locals {
  full_name   =   "app-${var.region}"
  is_prod =var.region == "us-east-1" ? true : false
}
EOF

# ── 4. Seed s3-demo workspace for force-unlock demo ──
mkdir -p /root/workspace/s3-demo
cat > /root/workspace/s3-demo/main.tf <<'EOTF'
terraform {
  required_version = ">= 1.0"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket         = "terraform-state"
    key            = "demo/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"

    access_key                  = "test"
    secret_key                  = "test"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    use_path_style              = true
    skip_s3_checksum            = true
    skip_region_validation      = true

    endpoints = {
      s3       = "http://localhost:4566"
      dynamodb = "http://localhost:4566"
    }
  }
}

resource "null_resource" "demo" {
  triggers = {
    id = "force-unlock-demo"
  }
}
EOTF

# ── 5. Install tools, start services, init workspaces ──
install_terraform
install_awscli
start_localstack

# Create S3 bucket and DynamoDB table for s3-demo
awslocal s3 mb s3://terraform-state --region us-east-1
awslocal dynamodb create-table \
  --table-name terraform-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1

# Init and apply s3-demo workspace (establishes state in S3)
cd /root/workspace/s3-demo
terraform init
terraform apply -auto-approve

# Init main workspace (local state, no remote)
cd /root/workspace
terraform init

install_theia_plugin
finish_setup
