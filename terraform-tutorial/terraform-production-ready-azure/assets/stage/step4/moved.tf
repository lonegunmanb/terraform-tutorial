moved { from = azurerm_resource_group.main to = module.networking.azurerm_resource_group.this }
moved { from = azurerm_virtual_network.main to = module.networking.azurerm_virtual_network.this }
moved { from = azurerm_subnet.web to = module.networking.azurerm_subnet.this["web"] }
moved { from = azurerm_subnet.app to = module.networking.azurerm_subnet.this["app"] }
moved { from = azurerm_subnet.data to = module.networking.azurerm_subnet.this["data"] }
moved { from = azurerm_public_ip.web to = module.web.azurerm_public_ip.web }
moved { from = azurerm_network_interface.web to = module.web.azurerm_network_interface.web }
moved { from = azurerm_network_interface_security_group_association.web to = module.web.azurerm_network_interface_security_group_association.web }
moved { from = azurerm_linux_virtual_machine.web to = module.web.azurerm_linux_virtual_machine.web }

moved { from = azurerm_storage_account.assets to = module.storage.azurerm_storage_account.assets }
moved { from = azurerm_storage_container.assets to = module.storage.azurerm_storage_container.assets }
moved { from = azurerm_dns_zone.app to = module.dns.azurerm_dns_zone.app }

moved { from = azurerm_network_security_group.web to = module.security.azurerm_network_security_group.web }
moved { from = azurerm_network_security_group.app to = module.security.azurerm_network_security_group.app }
moved { from = azurerm_network_security_group.data to = module.security.azurerm_network_security_group.data }
