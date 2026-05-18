terraform {
  required_version = ">= 1.5"
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

# ── 这些资源目前散落在根模块，需要提取到子模块 ──

resource "azurerm_storage_account" "user_uploads" {
  name                     = "moduseruploads"
  resource_group_name      = "refactor-rg"
  location                 = "eastus"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    Purpose = "uploads"
  }
}

resource "azurerm_storage_account" "user_backups" {
  name                     = "moduserbackups"
  resource_group_name      = "refactor-rg"
  location                 = "eastus"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    Purpose = "backups"
  }
}
