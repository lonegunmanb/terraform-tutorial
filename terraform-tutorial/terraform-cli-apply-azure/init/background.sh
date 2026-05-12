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
    image: ghcr.io/lonegunmanb/miniblue:sha-a1ad451
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

resource "azurerm_dns_zone" "app" {
  name                = "${var.app_name}-${var.environment}-app-${var.suffix}.local"
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

resource "azurerm_dns_zone" "logs" {
  name                = "${var.app_name}-${var.environment}-logs-${var.suffix}.local"
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

resource "azurerm_virtual_network" "net" {
  name                = "${var.app_name}-${var.environment}-vnet-${var.suffix}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

output "resource_group" {
  value = azurerm_resource_group.main.name
}

output "app_dns_zone" {
  value = azurerm_dns_zone.app.name
}

output "logs_dns_zone" {
  value = azurerm_dns_zone.logs.name
}

output "vnet" {
  value = azurerm_virtual_network.net.name
}
EOTF
fi

# ── 2. Install tooling ──
install_terraform
apt-get update -qq && apt-get install -y -qq jq > /dev/null 2>&1
start_miniblue
install_azlocal

# ── 3. Initialize providers (do NOT apply — students run apply themselves in step 1) ──
export SSL_CERT_FILE=/root/.miniblue/cert.pem
terraform init

finish_setup
