locals {
  name_prefix = "${var.app_name}-${var.environment}-${var.suffix}"
  common_tags = {
    App         = var.app_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_dns_zone" "app" {
  name                = "${local.name_prefix}.local"
  resource_group_name = var.resource_group_name
  tags                = local.common_tags
}
