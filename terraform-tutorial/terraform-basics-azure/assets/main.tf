terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# Configure the azurerm provider to talk to miniblue (local Azure emulator)
provider "azurerm" {
  features {}

  metadata_host                   = "localhost:4567"
  resource_provider_registrations = "none"

  # miniblue 接受任意凭据
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
