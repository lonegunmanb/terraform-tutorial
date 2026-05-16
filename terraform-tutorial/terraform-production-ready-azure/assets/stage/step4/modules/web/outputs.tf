output "web_vm_name" { value = azurerm_linux_virtual_machine.web.name }
output "web_private_ip" { value = azurerm_network_interface.web.private_ip_address }
