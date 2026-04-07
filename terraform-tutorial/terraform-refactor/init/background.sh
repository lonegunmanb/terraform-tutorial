#!/bin/bash
exec > /tmp/background.log 2>&1
set -x

source /root/setup-common.sh

# ── 1. Install tools ──
install_terraform
install_awscli

# ── 2. Start LocalStack ──
start_localstack

# ── 3. Pre-create S3 buckets for import exercise (step1) ──
# Wait for LocalStack S3 to be ready
for i in $(seq 1 30); do
  if awslocal s3 ls 2>/dev/null; then
    break
  fi
  sleep 2
done

awslocal s3 mb s3://legacy-app-data
awslocal s3 mb s3://legacy-app-logs

# ── 4. Pre-init & pre-apply step2 (removed needs existing state) ──
cd /root/workspace/step2
terraform init
terraform apply -auto-approve

# ── 5. Pre-init & pre-apply step3 (moved needs existing state) ──
cd /root/workspace/step3
terraform init
terraform apply -auto-approve

# ── 6. Pre-init & pre-apply step4 (moved into module needs existing state) ──
cd /root/workspace/step4
terraform init
terraform apply -auto-approve

# ── 7. Pre-init step1 ──
cd /root/workspace/step1
terraform init

# ── 8. Signal completion ──
finish_setup
