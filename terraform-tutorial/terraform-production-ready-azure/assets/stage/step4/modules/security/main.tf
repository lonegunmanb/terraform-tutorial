# 安全层：凭证管理与最小权限访问控制
# 对应三层架构中的安全横切关注点——Managed Identity 最小权限 + 凭证托管

data "azurerm_client_config" "current" {}

resource "azurerm_user_assigned_identity" "app" {
  name                = "${var.app_name}-${var.environment}-app-identity"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = {
    Name = "${var.app_name}-${var.environment}-app-identity"
  }
}

resource "azurerm_role_assignment" "storage_static" {
  scope                = var.static_storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

resource "azurerm_role_assignment" "storage_backups" {
  scope                = var.backup_storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

resource "azurerm_role_assignment" "cosmos" {
  scope                = var.cosmos_account_id
  role_definition_name = "Cosmos DB Account Reader Role"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

resource "azurerm_key_vault" "app" {
  name                       = substr("${var.app_name}-${var.environment}-kv", 0, 24)
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  enable_rbac_authorization  = true


  tags = {
    Name = "${var.app_name}-${var.environment}-kv"
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
  name                = "${var.app_name}-${var.environment}-appconfig"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "free"

  tags = {
    Name = "${var.app_name}-${var.environment}-appconfig"
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
