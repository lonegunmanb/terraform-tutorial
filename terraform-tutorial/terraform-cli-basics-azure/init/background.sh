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
    image: ghcr.io/lonegunmanb/miniblue:sha-11ef0e8
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

variable "app_name" {
  type        = string
  default     = "myapp"
  description = "应用名称"
}

variable "suffix" {
  type        = string
  default     = "lab"
  description = "资源名称后缀，避免命名冲突"
}

locals {
  name_prefix = "${var.app_name}-${var.environment}"
  common_tags = {
    Environment = var.environment
    App         = var.app_name
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_resource_group" "setup" {
  name     = "${local.name_prefix}-setup-${var.suffix}"
  location = "East US"
  tags     = local.common_tags
}

resource "azurerm_resource_group" "deploy" {
  depends_on = [azurerm_resource_group.setup]

  name     = "${local.name_prefix}-deploy-${var.suffix}"
  location = "East US"
  tags     = local.common_tags
}

output "name_prefix" {
  value       = local.name_prefix
  description = "资源名称前缀"
}

output "setup_rg" {
  value       = azurerm_resource_group.setup.name
  description = "setup 阶段的 Resource Group 名称"
}

output "deploy_rg" {
  value       = azurerm_resource_group.deploy.name
  description = "deploy 阶段的 Resource Group 名称"
}
EOTF
fi

# ── 2. Create local module for terraform get demo ──
mkdir -p /root/workspace/modules/greet
if [ ! -f /root/workspace/modules/greet/main.tf ]; then
cat > /root/workspace/modules/greet/main.tf <<'EOTF'
variable "name" {
  type    = string
  default = "World"
}

output "message" {
  value = "Hello, ${var.name}!"
}
EOTF
fi

# ── 3. Seed unformatted file for fmt demo ──
cat > /root/workspace/unformatted.tf <<'EOF'
# 格式化演示文件 —— 运行 terraform fmt 来修复此文件的缩进风格
variable "region" {
type    = string
default =  "East US"
description = "Azure region"
}
locals {
  full_name   =   "app-${var.region}"
  is_prod =var.region == "East US" ? true : false
}
EOF

# ── 4. Seed blob-demo workspace for force-unlock demo ──
# Uses the azurerm backend pointed at miniblue. State is stored in a blob in
# Azure Blob Storage; locking is implemented as a lease on that state blob.
# Step 5 will simulate an orphan lock by acquiring the lease via curl, then
# release it with `terraform force-unlock`. This mirrors the real azurerm
# backend lock/force-unlock workflow exactly.
mkdir -p /root/workspace/blob-demo
cat > /root/workspace/blob-demo/main.tf <<'EOTF'
terraform {
  required_version = ">= 1.0"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstateacct"
    container_name       = "tfstate"
    key                  = "demo.tfstate"

    metadata_host   = "localhost:4567"
    subscription_id = "00000000-0000-0000-0000-000000000000"
    tenant_id       = "00000000-0000-0000-0000-000000000001"
    client_id       = "miniblue"
    client_secret   = "miniblue"
  }
}

resource "null_resource" "demo" {
  triggers = {
    note = "state stored in Azure Blob Storage via miniblue"
  }
}
EOTF

# ── 5. Install tools, start services, init workspaces ──
install_terraform
apt-get update -qq && apt-get install -y -qq jq curl > /dev/null 2>&1
start_miniblue
install_azlocal

# Pre-create the resource group + storage account + container that the
# azurerm backend will write state into. azlocal talks to miniblue's ARM
# control plane over HTTP 4566 — no certificate or signing needed.
azlocal group create --name tfstate-rg --location eastus
azlocal storage account create \
  --name tfstateacct \
  --resource-group tfstate-rg \
  --location eastus \
  --sku Standard_LRS

# Containers are an ARM sub-resource of the storage account. azlocal does not
# expose a `storage container create` command for the ARM endpoint, so create
# it via plain curl against miniblue's ARM API.
curl -sf -X PUT \
  "http://localhost:4566/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/tfstate-rg/providers/Microsoft.Storage/storageAccounts/tfstateacct/blobServices/default/containers/tfstate?api-version=2023-01-01" \
  -H "Content-Type: application/json" \
  -d '{"properties":{"publicAccess":"None"}}' \
  > /dev/null

# Init + apply blob-demo so a real state blob exists in the container. The
# azurerm backend acquires a (legitimate) lease during apply and releases it
# at the end — leaving the blob ready for step 5's orphan-lock simulation.
cd /root/workspace/blob-demo
export SSL_CERT_FILE=/root/.miniblue/cert.pem
terraform init
terraform apply -auto-approve

# Init main workspace (azurerm provider, local backend).
# Do NOT apply — students focus on fmt/console/get/graph here, not on cloud
# resources. Pre-init keeps the workspace ready for `terraform fmt -check`,
# `terraform get`, `terraform graph` etc. without an extra wait.
cd /root/workspace
terraform init

install_theia_plugin
finish_setup
