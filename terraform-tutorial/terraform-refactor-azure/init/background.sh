#!/bin/bash
exec > /tmp/background.log 2>&1
set -x

source /root/setup-common.sh

# ── 1. Install tools ──────────────────────────────────────────────────────────
install_terraform
apt-get update -qq && apt-get install -y -qq jq curl > /dev/null 2>&1

# ── 2. Start miniblue ─────────────────────────────────────────────────────────
start_miniblue
install_azlocal

export SSL_CERT_FILE=/root/.miniblue/cert.pem

# ── 3. Pre-create shared resource group ───────────────────────────────────────
azlocal group create --name refactor-rg --location eastus

# ── 4. Pre-create "legacy" storage accounts (out-of-band) for step1 import ──
for name in legacyappdata legacyapplogs legacysvcorders legacysvcpayments legacysvcnotif; do
  azlocal storage account create \
    --name "$name" \
    --resource-group refactor-rg \
    --location eastus \
    --sku Standard_LRS
done

# ── 5. Pre-init & pre-apply step2 (removed needs existing state) ─────────────
cd /root/workspace/step2
terraform init -input=false
terraform apply -auto-approve -input=false

# ── 6. Pre-init & pre-apply step3 (moved needs existing state) ───────────────
cd /root/workspace/step3
terraform init -input=false
terraform apply -auto-approve -input=false

# ── 7. Pre-init & pre-apply step4 (moved into module needs existing state) ──
cd /root/workspace/step4
terraform init -input=false
terraform apply -auto-approve -input=false

# ── 8. Pre-init step1 (DO NOT apply — student writes the import blocks) ─────
cd /root/workspace/step1
terraform init -input=false

# ── 9. Signal completion ──────────────────────────────────────────────────────
install_theia_plugin
finish_setup
