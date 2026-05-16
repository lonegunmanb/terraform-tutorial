output "lb_public_ip" {
  value = azurerm_public_ip.lb.ip_address
}

output "lb_id" {
  value = azurerm_lb.this.id
}

output "backend_pool_id" {
  value = azurerm_lb_backend_address_pool.app.id
}

output "lb_nsg_id" {
  value = azurerm_network_security_group.lb.id
}

output "app_nsg_id" {
  value = azurerm_network_security_group.app.id
}

output "data_nsg_id" {
  value = azurerm_network_security_group.data.id
}

output "vm_id" {
  value = azurerm_linux_virtual_machine.app.id
}
