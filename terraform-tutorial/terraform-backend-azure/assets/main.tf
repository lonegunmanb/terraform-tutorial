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

# 应用资源组
resource "azurerm_resource_group" "demo" {
  name     = "demo-app-rg"
  location = "East US"
  tags = {
    Name      = "Demo Resource Group"
    ManagedBy = "Terraform"
  }
}

# 状态存储所用资源组
resource "azurerm_resource_group" "state" {
  name     = "tfstate-rg"
  location = "East US"
  tags = {
    Name      = "Terraform State RG"
    ManagedBy = "Terraform"
  }
}

# 状态 Storage Account —— 后续步骤将把 Terraform 状态迁移到这个账户
resource "azurerm_storage_account" "state" {
  name                     = "tfstatelab"
  resource_group_name      = azurerm_resource_group.state.name
  location                 = azurerm_resource_group.state.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    Name      = "Terraform State Storage"
    ManagedBy = "Terraform"
  }
}

# 状态 Blob Container
resource "azurerm_storage_container" "state" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}

output "demo_resource_group" {
  value = azurerm_resource_group.demo.name
}

output "state_storage_account" {
  value = azurerm_storage_account.state.name
}

output "state_container" {
  value = azurerm_storage_container.state.name
}
