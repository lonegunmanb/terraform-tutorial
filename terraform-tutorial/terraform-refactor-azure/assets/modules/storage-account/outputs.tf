output "id" {
  value       = azurerm_storage_account.this.id
  description = "Storage Account 资源 ID"
}

output "name" {
  value       = azurerm_storage_account.this.name
  description = "Storage Account 名称"
}
