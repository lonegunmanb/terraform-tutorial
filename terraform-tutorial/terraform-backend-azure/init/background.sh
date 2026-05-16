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
  miniblue:
    image: ghcr.io/lonegunmanb/miniblue:sha-cf2cb7f
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

  metadata_host                   = "localhost:4567"
  resource_provider_registrations = "none"

  subscription_id = "00000000-0000-0000-0000-000000000000"
  tenant_id       = "00000000-0000-0000-0000-000000000001"
  client_id       = "miniblue"
  client_secret   = "miniblue"
}

# 应用资源组
resource "azurerm_resource_group" "demo" {
  name     = "demo-app-rg"
  location = "East US"
  tags = {
    Name      = "Demo Resource Group"
    ManagedBy = "Terraform"
  }
}

# 状态存储所用资源组
resource "azurerm_resource_group" "state" {
  name     = "tfstate-rg"
  location = "East US"
  tags = {
    Name      = "Terraform State RG"
    ManagedBy = "Terraform"
  }
}

# 状态 Storage Account —— 后续步骤将把 Terraform 状态迁移到这个账户中
resource "azurerm_storage_account" "state" {
  name                     = "tfstatelab"
  resource_group_name      = azurerm_resource_group.state.name
  location                 = azurerm_resource_group.state.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    Name      = "Terraform State Storage"
    ManagedBy = "Terraform"
  }
}

# 状态 Blob Container
resource "azurerm_storage_container" "state" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}

output "demo_resource_group" {
  value = azurerm_resource_group.demo.name
}

output "state_storage_account" {
  value = azurerm_storage_account.state.name
}

output "state_container" {
  value = azurerm_storage_container.state.name
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
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}

  metadata_host                   = "localhost:4567"
  resource_provider_registrations = "none"

  subscription_id = "00000000-0000-0000-0000-000000000000"
  tenant_id       = "00000000-0000-0000-0000-000000000001"
  client_id       = "miniblue"
  client_secret   = "miniblue"
}

resource "azurerm_resource_group" "app" {
  name     = "partial-config-rg"
  location = "East US"
  tags = {
    Name      = "Partial Config Demo"
    ManagedBy = "Terraform"
  }
}

output "resource_group" {
  value = azurerm_resource_group.app.name
}
EOTF
fi

# ── 2. Install tooling ──
install_terraform
apt-get update -qq && apt-get install -y -qq jq > /dev/null 2>&1
start_miniblue
install_azlocal

# Set up Terraform plugin cache
export TF_PLUGIN_CACHE_DIR="/root/.terraform.d/plugin-cache"
mkdir -p "$TF_PLUGIN_CACHE_DIR"
cat > /root/.terraformrc <<'TFRC'
plugin_cache_dir = "/root/.terraform.d/plugin-cache"
TFRC

# ── 3. Pre-cache providers (azurerm + time) ──
export SSL_CERT_FILE=/root/.miniblue/cert.pem
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
