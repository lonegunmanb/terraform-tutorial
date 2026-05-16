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
    image: ghcr.io/lonegunmanb/miniblue:sha-cf2cb7f
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
  description = "资源组名称"
  value       = azurerm_resource_group.main.name
}

output "app_dns_zone" {
  description = "应用 DNS Zone 名称"
  value       = azurerm_dns_zone.app.name
}

output "logs_dns_zone" {
  description = "日志 DNS Zone 名称"
  value       = azurerm_dns_zone.logs.name
}

output "vnet" {
  description = "Virtual Network 名称"
  value       = azurerm_virtual_network.net.name
}

output "connection_string" {
  description = "应用连接信息（敏感）"
  sensitive   = true
  value       = "https://${azurerm_dns_zone.app.name}/api?token=miniblue-secret"
}

output "all_dns_zones" {
  description = "所有 DNS Zone 名称列表"
  value       = [azurerm_dns_zone.app.name, azurerm_dns_zone.logs.name]
}

output "resource_summary" {
  description = "资源摘要"
  value = {
    resource_group = azurerm_resource_group.main.name
    app_dns_zone   = azurerm_dns_zone.app.name
    logs_dns_zone  = azurerm_dns_zone.logs.name
    vnet           = azurerm_virtual_network.net.name
    environment    = var.environment
  }
}
EOTF
fi

# ── 2. Install tooling ──
install_terraform
apt-get update -qq && apt-get install -y -qq jq > /dev/null 2>&1
start_miniblue
install_azlocal

# ── 3. Initialize and apply (students need pre-existing state with outputs) ──
export SSL_CERT_FILE=/root/.miniblue/cert.pem
terraform init
terraform apply -auto-approve

install_theia_plugin
finish_setup
