#!/bin/bash
exec > /tmp/background.log 2>&1
set -x

source /root/setup-common.sh

# ── 1. Seed workspace files ──
mkdir -p /root/workspace
cd /root/workspace

if [ ! -f docker-compose.yml ]; then
cat > docker-compose.yml <<EOF
services:
  miniblue:
    image: ghcr.io/lonegunmanb/miniblue:sha-fcbf8f6
    ports:
      - "4566:4566"
      - "4567:4567"
    environment:
      - MINIBLUE_STORAGE_ENDPOINT=http://localhost:4566
      - MINIBLUE_DISABLE_SHAREDKEY_AUTH=1
    deploy:
      resources:
        limits:
          memory: 512M
EOF
fi

if [ ! -f main.tf ]; then
cat > main.tf <<'EOTF'
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}

  # miniblue HTTPS metadata endpoint
  metadata_host                   = "localhost:4567"
  resource_provider_registrations = "none"

  # miniblue 接受任意凭据
  subscription_id = "00000000-0000-0000-0000-000000000000"
  tenant_id       = "00000000-0000-0000-0000-000000000001"
  client_id       = "miniblue"
  client_secret   = "miniblue"
}
EOTF
fi

# Pre-stage foreach.tf in /root (Killercoda asset mechanism already places it
# there; this is a fallback when assets are missing).
if [ ! -f /root/foreach.tf ]; then
cat > /root/foreach.tf <<'EOTF'
# 用于 Step 2：for_each 导入
variable "rg_envs" {
  type    = set(string)
  default = ["dev", "staging"]
}

resource "azurerm_resource_group" "per_env" {
  for_each = var.rg_envs
  name     = "app-${each.key}-rg"
  location = "East US"
  tags = {
    Environment = each.key
    ManagedBy   = "Terraform"
  }
}
EOTF
fi

# ── 2. Install tooling ──
install_terraform
apt-get update -qq && apt-get install -y -qq jq curl > /dev/null 2>&1
start_miniblue
install_azlocal

# ── 3. Initialize Terraform (no apply — students import existing resources) ──
export SSL_CERT_FILE=/root/.miniblue/cert.pem
terraform init

# ── 4. Create "legacy" Azure resources via miniblue ARM API directly ──
# These resources are NOT managed by Terraform — students will import them.
# We use curl PUT against miniblue's ARM endpoint (HTTP 4566) so we can set
# tags in a single call. azlocal `group create` works too but its --tags
# support varies by version.
SUB=00000000-0000-0000-0000-000000000000
ARM=http://localhost:4566

# Step 1: a single "legacy" resource group with tags
curl -sf -X PUT \
  "${ARM}/subscriptions/${SUB}/resourceGroups/legacy-rg?api-version=2021-04-01" \
  -H "Content-Type: application/json" \
  -d '{"location":"eastus","tags":{"Environment":"production","Team":"backend"}}' \
  > /dev/null

# Step 2: per-env resource groups for for_each import (no tags — students
# add tags via Terraform after importing)
curl -sf -X PUT \
  "${ARM}/subscriptions/${SUB}/resourceGroups/app-dev-rg?api-version=2021-04-01" \
  -H "Content-Type: application/json" \
  -d '{"location":"eastus"}' \
  > /dev/null

curl -sf -X PUT \
  "${ARM}/subscriptions/${SUB}/resourceGroups/app-staging-rg?api-version=2021-04-01" \
  -H "Content-Type: application/json" \
  -d '{"location":"eastus"}' \
  > /dev/null

install_theia_plugin
finish_setup
