#!/bin/bash
exec > /tmp/background.log 2>&1
set -x

source /root/setup-common.sh

# ── 1. Seed workspace files (assets are copied by Killercoda; these are fallbacks) ──
mkdir -p /root/workspace
cd /root/workspace

if [ ! -f docker-compose.yml ]; then
cat > docker-compose.yml <<'EOF'
services:
  miniblue:
    image: ghcr.io/lonegunmanb/miniblue:sha-8cc1c25
    ports:
      - "4566:4566"
      - "4567:4567"
    deploy:
      resources:
        limits:
          memory: 512M
EOF
fi

if [ ! -f main.tf ]; then
  cp /root/main.tf /root/workspace/main.tf 2>/dev/null || true
fi

# Step 配置文件保留在 /root（已由 Killercoda asset 机制拷贝）

# ── 2. Install tooling ──
install_terraform
apt-get update -qq && apt-get install -y -qq jq > /dev/null 2>&1
start_miniblue
install_azlocal

# ── 3. Initialize and apply (students need pre-existing state to inspect) ──
export SSL_CERT_FILE=/root/.miniblue/cert.pem
terraform init
terraform apply -auto-approve

install_theia_plugin
finish_setup
