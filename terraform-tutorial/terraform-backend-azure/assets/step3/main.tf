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
