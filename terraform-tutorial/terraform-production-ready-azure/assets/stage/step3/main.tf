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
  suffix   = "lab"
  app_name = "${var.app_name}-${local.suffix}"
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

# ── 网络层 ────────────────────────────────────────────────────────────────
module "networking" {
  source = "./modules/networking"

  app_name    = local.app_name
  environment = var.environment
  vnet_cidr   = var.vnet_cidr
  location    = var.location
}

# ── Web 层 ──────────────────────────────────────────────────────────────
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

# ── 数据层（已提取为模块）────────────────────────────────────────────────
module "data" {
  source = "./modules/data"

  app_name            = local.app_name
  environment         = var.environment
  resource_group_name = module.networking.resource_group_name
  location            = module.networking.location
}

# ── 存储层（已提取为模块）────────────────────────────────────────────────
module "storage" {
  source = "./modules/storage"

  app_name            = local.app_name
  environment         = var.environment
  resource_group_name = module.networking.resource_group_name
  location            = module.networking.location
  suffix              = local.suffix
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
  scope                = module.storage.static_storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

resource "azurerm_role_assignment" "storage_backups" {
  scope                = module.storage.backup_storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

resource "azurerm_role_assignment" "cosmos" {
  scope                = module.data.cosmos_account_id
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
  enable_rbac_authorization  = true


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
  value = module.storage.static_storage_account_name
}

output "backup_storage_account" {
  value = module.storage.backup_storage_account_name
}

output "cosmos_account" {
  value = module.data.cosmos_account_name
}

output "app_identity_principal_id" {
  value = azurerm_user_assigned_identity.app.principal_id
}
