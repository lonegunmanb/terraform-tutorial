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
  description = "部署环境"
}

variable "app_name" {
  type        = string
  default     = "myapp"
  description = "应用名称"
}

variable "suffix" {
  type        = string
  default     = "lab"
  description = "资源名称后缀，用于避免命名冲突"
}

locals {
  common_tags = {
    Environment = var.environment
    App         = var.app_name
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_resource_group" "main" {
  name     = "${var.app_name}-${var.environment}-rg-${var.suffix}"
  location = "East US"
  tags     = local.common_tags
}

resource "azurerm_virtual_network" "net" {
  name                = "${var.app_name}-${var.environment}-vnet-${var.suffix}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

resource "azurerm_subnet" "app" {
  name                 = "${var.app_name}-${var.environment}-app-${var.suffix}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.net.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "logs" {
  name                 = "${var.app_name}-${var.environment}-logs-${var.suffix}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.net.name
  address_prefixes     = ["10.0.2.0/24"]
}

output "resource_group" {
  value = azurerm_resource_group.main.name
}

output "vnet" {
  value = azurerm_virtual_network.net.name
}

output "app_subnet" {
  value = azurerm_subnet.app.name
}

output "logs_subnet" {
  value = azurerm_subnet.logs.name
}
EOTF
fi

if [ ! -f dev.tfvars ]; then
cat > dev.tfvars <<'EOF'
environment = "dev"
app_name    = "myapp"
suffix      = "lab"
EOF
fi

if [ ! -f prod.tfvars ]; then
cat > prod.tfvars <<'EOF'
environment = "prod"
app_name    = "myapp"
suffix      = "lab"
EOF
fi

# ── 2. Install tooling & start miniblue ──
install_terraform
apt-get update -qq && apt-get install -y -qq jq > /dev/null 2>&1
start_miniblue
install_azlocal

# ── 3. Pre-apply resources so students can practice destroy ──
export SSL_CERT_FILE=/root/.miniblue/cert.pem
terraform init
terraform apply -auto-approve

# ── 4. Pre-init depends-demo (rename asset and download providers) ──
mkdir -p /root/workspace/depends-demo
if [ -f /root/workspace/depends-demo/vnet-main.tf ]; then
  mv /root/workspace/depends-demo/vnet-main.tf /root/workspace/depends-demo/main.tf
fi
cd /root/workspace/depends-demo
terraform init
cd /root/workspace

finish_setup
