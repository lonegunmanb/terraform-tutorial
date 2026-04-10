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
  cp /root/main.tf /root/workspace/main.tf
fi

# Keep extra asset files in /root for later use
# (already copied by Killercoda asset mechanism)

# ── 2. Install tooling ──
install_terraform
install_awscli
start_localstack

# ── 3. Initialize Terraform (no apply — students import existing resources) ──
terraform init

# ── 4. Create "legacy" resources via awslocal (not managed by Terraform) ──
# Step 1: single bucket for manual import
awslocal s3 mb s3://legacy-app
awslocal s3api put-bucket-tagging --bucket legacy-app --tagging 'TagSet=[{Key=Environment,Value=production},{Key=Team,Value=backend}]'

# Step 2: per-env buckets for for_each import
awslocal s3 mb s3://app-dev
awslocal s3 mb s3://app-staging

install_theia_plugin
finish_setup
