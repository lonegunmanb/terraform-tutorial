# 存储层：静态资源 + 数据备份
# 对应三层架构中的 CDN/静态资源层（生产环境搭配 Azure CDN / Front Door）

locals {
  # Azure storage account names: 3-24 chars, lowercase alphanumeric only
  storage_name_static  = substr(replace("${var.app_name}${var.environment}static${var.suffix}", "-", ""), 0, 24)
  storage_name_backups = substr(replace("${var.app_name}${var.environment}backups${var.suffix}", "-", ""), 0, 24)
}

resource "azurerm_storage_account" "static" {
  name                     = local.storage_name_static
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  blob_properties {
    versioning_enabled = var.enable_versioning
  }

  tags = {
    Name = "${var.app_name}-${var.suffix}-${var.environment}-static"
  }
}

resource "azurerm_storage_container" "static" {
  name                  = "static"
  storage_account_id    = azurerm_storage_account.static.id
  container_access_type = "private"
}

resource "azurerm_storage_account" "backups" {
  name                     = local.storage_name_backups
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  blob_properties {
    versioning_enabled = true
  }

  tags = {
    Name = "${var.app_name}-${var.suffix}-${var.environment}-backups"
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
        delete_after_days_since_modification_greater_than = var.backup_expiration_days
      }
    }
  }
}
