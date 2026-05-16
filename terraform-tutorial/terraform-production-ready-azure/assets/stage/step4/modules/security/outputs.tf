output "app_identity_id" {
  value = azurerm_user_assigned_identity.app.id
}

output "app_identity_principal_id" {
  value = azurerm_user_assigned_identity.app.principal_id
}

output "app_identity_name" {
  value = azurerm_user_assigned_identity.app.name
}

output "key_vault_id" {
  value = azurerm_key_vault.app.id
}

output "app_configuration_id" {
  value = azurerm_app_configuration.app.id
}
