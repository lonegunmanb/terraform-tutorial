# ── 第二步：网络层 + Web 层提取为模块 ──────────────────────────────────────
# 每个 moved 块告诉 Terraform：资源从旧地址搬到了新地址。
# 状态文件会更新地址，但不会销毁或重建任何基础设施资源。

# 网络层 ─────────────────────────────────────────────────────────────────────

moved {
  from = azurerm_resource_group.main
  to   = module.networking.azurerm_resource_group.main
}

moved {
  from = azurerm_virtual_network.main
  to   = module.networking.azurerm_virtual_network.this
}

# 子网从独立资源变为 for_each（以 CIDR 为 key）
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

# Web 层 ──────────────────────────────────────────────────────────────────────

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
