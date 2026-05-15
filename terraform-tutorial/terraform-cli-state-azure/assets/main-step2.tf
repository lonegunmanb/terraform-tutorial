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

# Step 2：app subnet 重命名为 application
resource "azurerm_subnet" "application" {
  name                 = "state-demo-app"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.net.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "logs" {
  name                 = "state-demo-logs"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.net.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "data" {
  name                 = "state-demo-data"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.net.name
  address_prefixes     = ["10.0.3.0/24"]
}
