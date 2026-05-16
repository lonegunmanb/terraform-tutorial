output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "location" {
  value = azurerm_resource_group.main.location
}

output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "vnet_name" {
  value = azurerm_virtual_network.this.name
}

output "public_subnet_ids" {
  value = [for s in azurerm_subnet.public : s.id]
}

output "private_subnet_ids" {
  value = [for s in azurerm_subnet.private : s.id]
}

output "public_subnets" {
  value = azurerm_subnet.public
}

output "private_subnets" {
  value = azurerm_subnet.private
}
