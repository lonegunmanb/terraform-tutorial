terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

locals {
  suffix               = "lab"
  app_name             = "${var.app_name}-${local.suffix}"
  storage_name_static  = substr(replace("${var.app_name}${var.environment}static${local.suffix}", "-", ""), 0, 24)
  storage_name_backups = substr(replace("${var.app_name}${var.environment}backups${local.suffix}", "-", ""), 0, 24)
}

resource "tls_private_key" "web_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
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
  type    = string
  default = "dev"
}

variable "app_name" {
  type    = string
  default = "webapp"
}

variable "vnet_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "location" {
  type    = string
  default = "East US"
}

# ── 网络层（已提取为模块）───────────────────────────────────────────────────
module "networking" {
  source = "./modules/networking"

  app_name    = local.app_name
  environment = var.environment
  vnet_cidr   = var.vnet_cidr
  location    = var.location
}

# ── Web 层（已提取为模块）─────────────────────────────────────────────────
module "web" {
  source = "./modules/web"

  app_name            = local.app_name
  environment         = var.environment
  resource_group_name = module.networking.resource_group_name
  location            = var.location
  vnet_id             = module.networking.vnet_id
  public_subnet_ids   = module.networking.public_subnet_ids
  private_subnet_ids  = module.networking.private_subnet_ids
  web_ssh_public_key  = tls_private_key.web_ssh.public_key_openssh
  app_identity_id     = azurerm_user_assigned_identity.app.id
}

# ══════════════════════════════════════════════════════════════════════════════
# 数据层（待提取）
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_cosmosdb_account" "users" {
  name                = "${local.app_name}-${var.environment}-cosmos"
  location            = module.networking.location
  resource_group_name = module.networking.resource_group_name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = module.networking.location
    failover_priority = 0
  }

  capabilities {
    name = "EnableTable"
  }

  tags = {
    Name = "${local.app_name}-${var.environment}-cosmos"
  }
}

resource "azurerm_cosmosdb_table" "users" {
  name                = "users"
  resource_group_name = module.networking.resource_group_name
  account_name        = azurerm_cosmosdb_account.users.name
}

# ══════════════════════════════════════════════════════════════════════════════
# 存储层（待提取）
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_storage_account" "static" {
  name                     = local.storage_name_static
  resource_group_name      = module.networking.resource_group_name
  location                 = module.networking.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  blob_properties {
    versioning_enabled = true
  }

  tags = {
    Name = "${local.app_name}-${var.environment}-static"
  }
}

resource "azurerm_storage_container" "static" {
  name                  = "static"
  storage_account_id    = azurerm_storage_account.static.id
  container_access_type = "private"
}

resource "azurerm_storage_account" "backups" {
  name                     = local.storage_name_backups
  resource_group_name      = module.networking.resource_group_name
  location                 = module.networking.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  blob_properties {
    versioning_enabled = true
  }

  tags = {
    Name = "${local.app_name}-${var.environment}-backups"
  }
}

resource "azurerm_storage_container" "backups" {
  name                  = "backups"
  storage_account_id    = azurerm_storage_account.backups.id
  container_access_type = "private"
}

resource "azurerm_storage_management_policy" "backups" {
  storage_account_id = azurerm_storage_account.backups.id

  rule {
    name    = "expire-old-backups"
    enabled = true
    filters {
      blob_types = ["blockBlob"]
    }
    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = 90
      }
    }
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# 安全与配置（待提取）
# ══════════════════════════════════════════════════════════════════════════════

data "azurerm_client_config" "current" {}

resource "azurerm_user_assigned_identity" "app" {
  name                = "${local.app_name}-${var.environment}-app-identity"
  resource_group_name = module.networking.resource_group_name
  location            = module.networking.location

  tags = {
    Name = "${local.app_name}-${var.environment}-app-identity"
  }
}

resource "azurerm_role_assignment" "storage_static" {
  scope                = azurerm_storage_account.static.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

resource "azurerm_role_assignment" "storage_backups" {
  scope                = azurerm_storage_account.backups.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

resource "azurerm_role_assignment" "cosmos" {
  scope                = azurerm_cosmosdb_account.users.id
  role_definition_name = "Cosmos DB Account Reader Role"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

resource "azurerm_key_vault" "app" {
  name                       = substr("${local.app_name}-${var.environment}-kv", 0, 24)
  location                   = module.networking.location
  resource_group_name        = module.networking.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  rbac_authorization_enabled = true


  tags = {
    Name = "${local.app_name}-${var.environment}-kv"
  }
}

resource "azurerm_key_vault_secret" "db_credentials" {
  name = "db-credentials"
  value = jsonencode({
    username = "app_user"
    password = "change-me-in-production"
    host     = "db.internal"
    port     = 5432
  })
  key_vault_id = azurerm_key_vault.app.id
}

resource "azurerm_app_configuration" "app" {
  name                = "${local.app_name}-${var.environment}-appconfig"
  resource_group_name = module.networking.resource_group_name
  location            = module.networking.location
  sku                 = "free"

  tags = {
    Name = "${local.app_name}-${var.environment}-appconfig"
  }
}

resource "azurerm_role_assignment" "appconfig" {
  scope                = azurerm_app_configuration.app.id
  role_definition_name = "App Configuration Data Reader"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

resource "azurerm_role_assignment" "keyvault" {
  scope                = azurerm_key_vault.app.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

# ══════════════════════════════════════════════════════════════════════════════
# 输出
# ══════════════════════════════════════════════════════════════════════════════

output "resource_group_name" {
  value = module.networking.resource_group_name
}

output "vnet_id" {
  value = module.networking.vnet_id
}

output "lb_public_ip" {
  value = module.web.lb_public_ip
}

output "static_storage_account" {
  value = azurerm_storage_account.static.name
}

output "backup_storage_account" {
  value = azurerm_storage_account.backups.name
}

output "cosmos_account" {
  value = azurerm_cosmosdb_account.users.name
}

output "app_identity_principal_id" {
  value = azurerm_user_assigned_identity.app.principal_id
}
