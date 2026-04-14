#!/bin/bash
exec > /tmp/background.log 2>&1
set -x

source /root/setup-common.sh

# ── 1. Prepare workspace ──
mkdir -p /root/workspace/policy
cd /root/workspace

# Seed main.tf if not already present
if [ ! -f /root/workspace/main.tf ]; then
cat > /root/workspace/main.tf <<'EOTF'
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

resource "aws_s3_bucket" "data" {
  bucket        = "my-data-bucket"
  force_destroy = true

  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket" "logs" {
  bucket        = "my-logs-bucket"
  force_destroy = true
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Deployment environment"
}

output "data_bucket_id" {
  value       = aws_s3_bucket.data.id
  description = "The ID of the data bucket"
}

output "logs_bucket_id" {
  value       = aws_s3_bucket.logs.id
  description = "The ID of the logs bucket"
}
EOTF
fi

# ── 2. Install tooling ──
install_terraform
start_localstack

# Install conftest
CONFTEST_VERSION="0.56.0"
echo "安装 Conftest..."
curl --connect-timeout 10 --max-time 120 -fsSL \
  "https://github.com/open-policy-agent/conftest/releases/download/v${CONFTEST_VERSION}/conftest_${CONFTEST_VERSION}_Linux_x86_64.tar.gz" \
  -o /tmp/conftest.tar.gz \
  && tar xzf /tmp/conftest.tar.gz -C /usr/local/bin conftest \
  && rm -f /tmp/conftest.tar.gz
conftest --version || echo "WARNING: conftest install failed"

# ── 3. Generate initial terraform plan ──
cd /root/workspace
terraform init
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > tfplan.json

install_theia_plugin
finish_setup
