#!/bin/bash
exec > /tmp/background.log 2>&1
set -x

source /root/setup-common.sh

# ── 1. Install tools ──────────────────────────────────────────────────────────
install_terraform
install_terragrunt
apt-get update -qq && apt-get install -y -qq jq > /dev/null 2>&1

# ── 2. Start miniblue ─────────────────────────────────────────────────────────
start_miniblue
install_azlocal

# ── 3. Pre-init workspace ─────────────────────────────────────────────────────
export SSL_CERT_FILE=/root/.miniblue/cert.pem
cd /root/workspace
terraform init -input=false

# ── 4. Signal setup complete ──────────────────────────────────────────────────
finish_setup
