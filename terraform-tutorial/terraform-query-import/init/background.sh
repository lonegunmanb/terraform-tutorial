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
  required_version = ">= 1.5"
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
EOTF
fi

# ── 2. Install tooling ──
install_terraform
install_awscli
start_localstack

# ── 3. Wait for LocalStack, then create "existing" resources ──
echo "等待 LocalStack 就绪..."
for i in $(seq 1 30); do
  if awslocal s3 ls >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

# Create pre-existing S3 buckets (not managed by Terraform)
awslocal s3 mb s3://app-prod-data
awslocal s3 mb s3://app-prod-logs
awslocal s3 mb s3://app-prod-assets
awslocal s3 mb s3://app-staging-data
awslocal s3 mb s3://app-staging-logs

# Create pre-existing DynamoDB tables
awslocal dynamodb create-table \
  --table-name app-prod-sessions \
  --attribute-definitions AttributeName=SessionID,AttributeType=S \
  --key-schema AttributeName=SessionID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST

awslocal dynamodb create-table \
  --table-name app-prod-cache \
  --attribute-definitions AttributeName=CacheKey,AttributeType=S \
  --key-schema AttributeName=CacheKey,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST

# ── 4. Init Terraform ──
cd /root/workspace
terraform init

install_theia_plugin
finish_setup
