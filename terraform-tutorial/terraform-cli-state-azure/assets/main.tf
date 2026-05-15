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

resource "azurerm_resource_group" "main" {
  name     = "state-demo-rg"
  location = "East US"
  tags = {
    Name        = "State Demo RG"
    Environment = "production"
  }
}

resource "azurerm_dns_zone" "app" {
  name                = "state-demo-app.local"
  resource_group_name = azurerm_resource_group.main.name
  tags = {
    Name        = "Application DNS Zone"
    Environment = "production"
  }
}

resource "azurerm_dns_zone" "logs" {
  name                = "state-demo-logs.local"
  resource_group_name = azurerm_resource_group.main.name
  tags = {
    Name        = "Logs DNS Zone"
    Environment = "production"
  }
}

resource "azurerm_dns_zone" "data" {
  name                = "state-demo-data.local"
  resource_group_name = azurerm_resource_group.main.name
  tags = {
    Name        = "Data DNS Zone"
    Environment = "staging"
  }
}

resource "azurerm_virtual_network" "net" {
  name                = "state-demo-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags = {
    Name        = "Demo VNet"
    Environment = "production"
  }
}
