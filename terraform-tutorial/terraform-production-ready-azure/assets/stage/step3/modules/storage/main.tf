locals {
  common_tags = {
    App         = var.app_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_storage_account" "assets" {
  name                     = "${var.app_name}${var.environment}${var.suffix}assets"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.common_tags

  lifecycle {
    postcondition {
      condition     = self.account_tier == "Standard"
      error_message = "演示环境的存储账户必须保持 Standard 层级，避免误用高成本配置。"
    }
  }
}

resource "azurerm_storage_container" "assets" {
  name                  = "static-assets"
  storage_account_id    = azurerm_storage_account.assets.id
  container_access_type = "private"
}
