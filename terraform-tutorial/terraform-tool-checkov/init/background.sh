#!/bin/bash
exec > /tmp/background.log 2>&1
set -x

source /root/setup-common.sh

# ── 1. Prepare workspace ──
mkdir -p /root/workspace
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

# Install Checkov in a virtual environment (PEP 668 — system Python is externally managed)
echo "安装 Checkov..."
apt-get install -y -qq python3-pip python3-venv > /dev/null 2>&1
python3 -m venv /opt/checkov
/opt/checkov/bin/pip install --upgrade pip > /dev/null 2>&1
/opt/checkov/bin/pip install checkov > /dev/null 2>&1
ln -sf /opt/checkov/bin/checkov /usr/local/bin/checkov
checkov --version || echo "WARNING: checkov install failed"

# Create custom policy directory for step2
mkdir -p /root/workspace/custom-policies

cat > /root/workspace/custom-policies/require_tags.yaml <<'POLICY'
metadata:
  id: "CUSTOM_AWS_1"
  name: "Ensure all S3 buckets have required tags"
  severity: "HIGH"
  category: "GENERAL_SECURITY"
definition:
  and:
    - cond_type: "attribute"
      resource_types:
        - "aws_s3_bucket"
      attribute: "tags.Environment"
      operator: "exists"
    - cond_type: "attribute"
      resource_types:
        - "aws_s3_bucket"
      attribute: "tags.ManagedBy"
      operator: "exists"
POLICY

install_theia_plugin
finish_setup
