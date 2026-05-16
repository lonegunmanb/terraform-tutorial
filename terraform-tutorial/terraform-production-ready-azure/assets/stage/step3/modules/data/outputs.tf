output "cosmos_account_name" {
  value = azurerm_cosmosdb_account.users.name
}

output "cosmos_account_id" {
  value = azurerm_cosmosdb_account.users.id
}

output "cosmos_table_name" {
  value = azurerm_cosmosdb_table.users.name
}
