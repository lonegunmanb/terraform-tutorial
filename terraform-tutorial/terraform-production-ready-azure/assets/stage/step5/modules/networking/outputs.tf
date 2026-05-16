output "resource_group_name" { value = azurerm_resource_group.this.name }
output "location" { value = azurerm_resource_group.this.location }
output "vnet_name" { value = azurerm_virtual_network.this.name }
output "web_subnet_id" { value = azurerm_subnet.this["web"].id }
output "app_subnet_id" { value = azurerm_subnet.this["app"].id }
output "data_subnet_id" { value = azurerm_subnet.this["data"].id }
