# ── 第二步：网络层 + Web 层提取为模块 ──────────────────────────────────────

# 网络层
moved {
  from = azurerm_resource_group.main
  to   = module.networking.azurerm_resource_group.main
}

moved {
  from = azurerm_virtual_network.main
  to   = module.networking.azurerm_virtual_network.this
}

moved {
  from = azurerm_subnet.public_a
  to   = module.networking.azurerm_subnet.public["10.0.1.0/24"]
}

moved {
  from = azurerm_subnet.public_b
  to   = module.networking.azurerm_subnet.public["10.0.2.0/24"]
}

moved {
  from = azurerm_subnet.private_a
  to   = module.networking.azurerm_subnet.private["10.0.11.0/24"]
}

moved {
  from = azurerm_subnet.private_b
  to   = module.networking.azurerm_subnet.private["10.0.12.0/24"]
}

# Web 层
moved {
  from = azurerm_network_security_group.lb
  to   = module.web.azurerm_network_security_group.lb
}

moved {
  from = azurerm_network_security_group.app
  to   = module.web.azurerm_network_security_group.app
}

moved {
  from = azurerm_network_security_group.data
  to   = module.web.azurerm_network_security_group.data
}

moved {
  from = azurerm_subnet_network_security_group_association.public_a
  to   = module.web.azurerm_subnet_network_security_group_association.public["10.0.1.0/24"]
}

moved {
  from = azurerm_subnet_network_security_group_association.public_b
  to   = module.web.azurerm_subnet_network_security_group_association.public["10.0.2.0/24"]
}

moved {
  from = azurerm_subnet_network_security_group_association.private_a
  to   = module.web.azurerm_subnet_network_security_group_association.private["10.0.11.0/24"]
}

moved {
  from = azurerm_subnet_network_security_group_association.private_b
  to   = module.web.azurerm_subnet_network_security_group_association.private["10.0.12.0/24"]
}

moved {
  from = azurerm_public_ip.lb
  to   = module.web.azurerm_public_ip.lb
}

moved {
  from = azurerm_lb.web
  to   = module.web.azurerm_lb.this
}

moved {
  from = azurerm_lb_backend_address_pool.app
  to   = module.web.azurerm_lb_backend_address_pool.app
}

moved {
  from = azurerm_lb_probe.http
  to   = module.web.azurerm_lb_probe.http
}

moved {
  from = azurerm_lb_rule.http
  to   = module.web.azurerm_lb_rule.http
}

moved {
  from = azurerm_network_interface.app
  to   = module.web.azurerm_network_interface.app
}

moved {
  from = azurerm_network_interface_backend_address_pool_association.app
  to   = module.web.azurerm_network_interface_backend_address_pool_association.app
}

moved {
  from = azurerm_linux_virtual_machine.app
  to   = module.web.azurerm_linux_virtual_machine.app
}

# ── 第三步：数据层 + 存储层提取为模块 ──────────────────────────────────────

# 数据层
moved {
  from = azurerm_cosmosdb_account.users
  to   = module.data.azurerm_cosmosdb_account.users
}

moved {
  from = azurerm_cosmosdb_table.users
  to   = module.data.azurerm_cosmosdb_table.users
}

# 存储层
moved {
  from = azurerm_storage_account.static
  to   = module.storage.azurerm_storage_account.static
}

moved {
  from = azurerm_storage_container.static
  to   = module.storage.azurerm_storage_container.static
}

moved {
  from = azurerm_storage_account.backups
  to   = module.storage.azurerm_storage_account.backups
}

moved {
  from = azurerm_storage_container.backups
  to   = module.storage.azurerm_storage_container.backups
}

moved {
  from = azurerm_storage_management_policy.backups
  to   = module.storage.azurerm_storage_management_policy.backups
}

# ── 第四步：安全层提取为模块 ──────────────────────────────────────────────

moved {
  from = azurerm_user_assigned_identity.app
  to   = module.security.azurerm_user_assigned_identity.app
}

moved {
  from = azurerm_role_assignment.storage_static
  to   = module.security.azurerm_role_assignment.storage_static
}

moved {
  from = azurerm_role_assignment.storage_backups
  to   = module.security.azurerm_role_assignment.storage_backups
}

moved {
  from = azurerm_role_assignment.cosmos
  to   = module.security.azurerm_role_assignment.cosmos
}

moved {
  from = azurerm_key_vault.app
  to   = module.security.azurerm_key_vault.app
}

moved {
  from = azurerm_key_vault_secret.db_credentials
  to   = module.security.azurerm_key_vault_secret.db_credentials
}

moved {
  from = azurerm_app_configuration.app
  to   = module.security.azurerm_app_configuration.app
}

moved {
  from = azurerm_role_assignment.appconfig
  to   = module.security.azurerm_role_assignment.appconfig
}

moved {
  from = azurerm_role_assignment.keyvault
  to   = module.security.azurerm_role_assignment.keyvault
}
