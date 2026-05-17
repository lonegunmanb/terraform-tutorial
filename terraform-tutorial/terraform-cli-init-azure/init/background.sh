#!/bin/bash
exec > /tmp/background.log 2>&1
set -x

source /root/setup-common.sh

# ── 1. Seed main workspace (DO NOT terraform init here — student does it in step 1) ──
mkdir -p /root/workspace
cd /root/workspace

if [ ! -f docker-compose.yml ]; then
cat > docker-compose.yml <<EOF
services:
  miniblue:
    image: ghcr.io/lonegunmanb/miniblue:sha-decf9af
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

variable "environment" {
  type        = string
  default     = "dev"
  description = "部署环境（dev / staging / prod）"
}

resource "azurerm_resource_group" "demo" {
  name     = "init-demo-${var.environment}-rg"
  location = "East US"
  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

output "resource_group" {
  value       = azurerm_resource_group.demo.name
  description = "演示用 Resource Group 名称"
}
EOTF
fi

# ── 2. Create backend-demo workspace for step 3 (Backend migration demo) ──
mkdir -p /root/workspace/backend-demo

cat > /root/workspace/backend-demo/main.tf <<'EOTF'
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

resource "azurerm_resource_group" "demo" {
  name     = "init-migrate-demo-rg"
  location = "East US"
  tags = {
    Note      = "backend migration demo"
    ManagedBy = "Terraform"
  }
}

output "message" {
  value = "backend migration demo"
}
EOTF

# Seed the azurerm backend config example — student copies this in step 3
cat > /root/workspace/backend-demo/backend.tf.example <<'EOTF'
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstateinit"
    container_name       = "tfstate"
    key                  = "demo/terraform.tfstate"

    # 指向 miniblue 的 HTTPS ARM metadata 端点
    metadata_host = "localhost:4567"

    # miniblue 接受任意凭据
    subscription_id = "00000000-0000-0000-0000-000000000000"
    tenant_id       = "00000000-0000-0000-0000-000000000001"
    client_id       = "miniblue"
    client_secret   = "miniblue"
  }
}
EOTF

# ── 3. Install tools, start miniblue ──
install_terraform
apt-get update -qq && apt-get install -y -qq jq curl > /dev/null 2>&1
start_miniblue
install_azlocal

# ── 4. Pre-create state Storage Account + Container in miniblue ──
# Uses azlocal for ARM control plane (group/storage account); container is an
# ARM sub-resource that azlocal does not currently expose as a CLI subcommand,
# so we create it via raw curl against miniblue's ARM API.
azlocal group create --name tfstate-rg --location eastus
azlocal storage account create \
  --name tfstateinit \
  --resource-group tfstate-rg \
  --location eastus \
  --sku Standard_LRS

curl -sf -X PUT \
  "http://localhost:4566/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/tfstate-rg/providers/Microsoft.Storage/storageAccounts/tfstateinit/blobServices/default/containers/tfstate?api-version=2023-01-01" \
  -H "Content-Type: application/json" \
  -d '{"properties":{"publicAccess":"None"}}' \
  > /dev/null

# ── 5. Init and apply backend-demo to create local terraform.tfstate ──
# (Student will later migrate this state to azurerm backend in step 3)
export SSL_CERT_FILE=/root/.miniblue/cert.pem
cd /root/workspace/backend-demo
terraform init
terraform apply -auto-approve

# ── 6. Finish setup ──
install_theia_plugin
finish_setup
