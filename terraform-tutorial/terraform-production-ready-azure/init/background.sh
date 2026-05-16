#!/bin/bash
exec > /tmp/background.log 2>&1
set -x

source /root/setup-common.sh

mkdir -p /root/workspace
cd /root/workspace

if [ ! -f docker-compose.yml ]; then
cat > docker-compose.yml <<'EOF'
services:
  miniblue:
    image: ghcr.io/lonegunmanb/miniblue:sha-2fead35
    ports:
      - "4566:4566"
      - "4567:4567"
    environment:
      MINIBLUE_STORAGE_ENDPOINT: http://localhost:4566
      MINIBLUE_DISABLE_SHAREDKEY_AUTH: "1"
    deploy:
      resources:
        limits:
          memory: 512M
EOF
fi

install_terraform
install_terragrunt
start_miniblue
install_azlocal
install_theia_plugin || true

export SSL_CERT_FILE=/root/.miniblue/cert.pem
terraform init -input=false

finish_setup
