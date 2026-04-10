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

# ── 2. Install tooling ──
install_terraform
install_awscli
start_localstack

# ── 3. Initialize and apply (students need pre-existing state with outputs) ──
terraform init
terraform apply -auto-approve

install_theia_plugin
finish_setup
