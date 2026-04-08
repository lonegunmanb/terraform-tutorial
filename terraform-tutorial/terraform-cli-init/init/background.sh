#!/bin/bash
exec > /tmp/background.log 2>&1
set -x

source /root/setup-common.sh

# ── 1. Seed main workspace (DO NOT terraform init here — student does it in step 1) ──
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
      - SERVICES=s3
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

resource "null_resource" "demo" {
  triggers = {
    env = var.environment
  }
}

output "environment" {
  value       = var.environment
  description = "当前部署环境"
}
EOTF
fi

# ── 2. Create backend-demo workspace for step 3 (Backend migration demo) ──
mkdir -p /root/workspace/backend-demo

cat > /root/workspace/backend-demo/main.tf <<'EOTF'
terraform {
  required_version = ">= 1.0"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

resource "null_resource" "demo" {
  triggers = {
    id = "migrate-demo"
  }
}

output "message" {
  value = "backend migration demo"
}
EOTF

# Seed the S3 backend config example — student copies this in step 3
cat > /root/workspace/backend-demo/backend.tf.example <<'EOTF'
terraform {
  backend "s3" {
    bucket = "tf-init-demo-state"
    key    = "demo/terraform.tfstate"
    region = "us-east-1"

    access_key                  = "test"
    secret_key                  = "test"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    use_path_style              = true
    skip_s3_checksum            = true
    skip_region_validation      = true

    endpoints = {
      s3 = "http://localhost:4566"
    }
  }
}
EOTF

# ── 3. Install tools, start LocalStack ──
install_terraform
install_awscli
start_localstack

# Create S3 bucket for backend migration demo
awslocal s3 mb s3://tf-init-demo-state --region us-east-1

# Init and apply backend-demo to create local terraform.tfstate
# (Student will later migrate this to S3 in step 3)
cd /root/workspace/backend-demo
terraform init
terraform apply -auto-approve

# ── 4. Finish setup ──
install_theia_plugin
finish_setup
