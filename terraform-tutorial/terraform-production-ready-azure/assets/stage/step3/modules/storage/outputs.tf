output "static_storage_account_name" {
  value = azurerm_storage_account.static.name
}

output "static_storage_account_id" {
  value = azurerm_storage_account.static.id
}

output "backup_storage_account_name" {
  value = azurerm_storage_account.backups.name
}

output "backup_storage_account_id" {
  value = azurerm_storage_account.backups.id
}
