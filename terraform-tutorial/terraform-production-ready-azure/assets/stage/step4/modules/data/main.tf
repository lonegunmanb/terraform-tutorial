# 数据层：Cosmos DB

resource "azurerm_cosmosdb_account" "users" {
  name                = "${var.app_name}-${var.environment}-cosmos"
  location            = var.location
  resource_group_name = var.resource_group_name
  offer_type          = var.offer_type
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  capabilities {
    name = "EnableTable"
  }

  tags = {
    Name = "${var.app_name}-${var.environment}-cosmos"
  }

  lifecycle {
    postcondition {
      condition     = self.offer_type == "Standard"
      error_message = "Cosmos DB 帐户必须使用 Standard offer_type，避免过度预置。"
    }
  }
}

resource "azurerm_cosmosdb_table" "users" {
  name                = "users"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.users.name
}
