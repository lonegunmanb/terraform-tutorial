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
    image: ghcr.io/lonegunmanb/miniblue:sha-fcbf8f6
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

resource "azurerm_resource_group" "tutorial" {
  name     = "TerraformTutorial-rg"
  location = "East US"

  tags = {
    Name = "TerraformTutorial"
  }
}

resource "azurerm_virtual_network" "tutorial" {
  name                = "TerraformTutorial-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.tutorial.location
  resource_group_name = azurerm_resource_group.tutorial.name

  tags = {
    Name = "TerraformTutorial"
  }
}

output "resource_group_name" {
  value       = azurerm_resource_group.tutorial.name
  description = "The name of the resource group"
}

output "vnet_name" {
  value       = azurerm_virtual_network.tutorial.name
  description = "The name of the virtual network"
}

output "vnet_address_space" {
  value       = azurerm_virtual_network.tutorial.address_space
  description = "The address space of the virtual network"
}
EOTF
fi

# ── 2. Install tools & start services ──
install_terraform
start_miniblue
install_azlocal

finish_setup
