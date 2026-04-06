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

resource "aws_s3_bucket" "demo" {
  bucket = "demo-app-bucket"
  tags = {
    Name      = "Demo Bucket"
    ManagedBy = "Terraform"
  }
}

resource "aws_s3_bucket" "state" {
  bucket = "terraform-state-bucket"
  tags = {
    Name      = "Terraform State Bucket"
    ManagedBy = "Terraform"
  }
}

output "demo_bucket" {
  value = aws_s3_bucket.demo.bucket
}

output "state_bucket" {
  value = aws_s3_bucket.state.bucket
}
EOTF
fi

# Seed step3 workspace
mkdir -p /root/workspace/step3
if [ ! -f /root/workspace/step3/main.tf ]; then
cat > /root/workspace/step3/main.tf <<'EOTF'
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

resource "aws_s3_bucket" "app" {
  bucket = "partial-config-bucket"
  tags = {
    Name      = "Partial Config Demo"
    ManagedBy = "Terraform"
  }
}

output "bucket_name" {
  value = aws_s3_bucket.app.bucket
}
EOTF
fi

# ── 2. Install tools ──
install_terraform
install_awscli

# Set up Terraform plugin cache for faster re-init
export TF_PLUGIN_CACHE_DIR="/root/.terraform.d/plugin-cache"
mkdir -p "$TF_PLUGIN_CACHE_DIR"
cat > /root/.terraformrc <<'TFRC'
plugin_cache_dir = "/root/.terraform.d/plugin-cache"
TFRC

# ── 3. Start LocalStack ──
start_localstack

# ── 4. Pre-create DynamoDB lock table ──
awslocal dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST

# ── 5. Pre-cache Terraform providers (aws + time) ──
cd /root/workspace
cat > _time_provider.tf <<'EOTF'
terraform {
  required_providers {
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}
EOTF
terraform init -input=false
rm -f _time_provider.tf
rm -rf .terraform .terraform.lock.hcl

finish_setup
terraform init -input=false
terraform apply -auto-approve -input=false

finish_setup
