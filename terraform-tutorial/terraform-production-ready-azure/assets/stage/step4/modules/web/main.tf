resource "azurerm_network_security_group" "lb" {
  name                = "${var.app_name}-${var.environment}-lb-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "allow-http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Name = "${var.app_name}-${var.environment}-lb-nsg"
  }

  lifecycle {
    ignore_changes = [security_rule]
  }
}

resource "azurerm_network_security_group" "app" {
  name                = "${var.app_name}-${var.environment}-app-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "allow-http-from-lb"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "*"
  }

  tags = {
    Name = "${var.app_name}-${var.environment}-app-nsg"
  }

  lifecycle {
    ignore_changes = [security_rule]
  }
}

resource "azurerm_network_security_group" "data" {
  name                = "${var.app_name}-${var.environment}-data-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "allow-db-from-app"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "10.0.11.0/24"
    destination_address_prefix = "*"
  }

  tags = {
    Name = "${var.app_name}-${var.environment}-data-nsg"
  }

  lifecycle {
    ignore_changes = [security_rule]
  }
}

resource "azurerm_subnet_network_security_group_association" "public" {
  for_each = { for idx, id in var.public_subnet_ids : var.public_subnet_cidrs[idx] => id }

  subnet_id                 = each.value
  network_security_group_id = azurerm_network_security_group.lb.id
}

resource "azurerm_subnet_network_security_group_association" "private" {
  for_each = { for idx, id in var.private_subnet_ids : var.private_subnet_cidrs[idx] => id }

  subnet_id                 = each.value
  network_security_group_id = azurerm_network_security_group.app.id
}

resource "azurerm_public_ip" "lb" {
  name                = "${var.app_name}-${var.environment}-lb-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Name = "${var.app_name}-${var.environment}-lb-pip"
  }
}

resource "azurerm_lb" "this" {
  name                = "${var.app_name}-${var.environment}-lb"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "frontend"
    public_ip_address_id = azurerm_public_ip.lb.id
  }

  tags = {
    Name = "${var.app_name}-${var.environment}-lb"
  }

  lifecycle {
    precondition {
      condition     = length(var.public_subnet_ids) >= 2
      error_message = "Load Balancer 至少需要 2 个不同可用区的子网才能实现高可用。当前只有 ${length(var.public_subnet_ids)} 个。"
    }
  }
}

resource "azurerm_lb_backend_address_pool" "app" {
  name            = "${var.app_name}-${var.environment}-backend"
  loadbalancer_id = azurerm_lb.this.id
}

resource "azurerm_lb_probe" "http" {
  name                = "http-probe"
  loadbalancer_id     = azurerm_lb.this.id
  protocol            = "Http"
  port                = 80
  request_path        = "/"
  interval_in_seconds = 15
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "http" {
  name                           = "http-rule"
  loadbalancer_id                = azurerm_lb.this.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.app.id]
  probe_id                       = azurerm_lb_probe.http.id
}

resource "azurerm_network_interface" "app" {
  name                = "${var.app_name}-${var.environment}-app-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.private_subnet_ids[0]
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    Name = "${var.app_name}-${var.environment}-app-nic"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "app" {
  network_interface_id    = azurerm_network_interface.app.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.app.id
}

resource "azurerm_linux_virtual_machine" "app" {
  name                            = "${var.app_name}-${var.environment}-app-vm"
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = "Standard_B1s"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.web_ssh_public_key
  }
  network_interface_ids = [azurerm_network_interface.app.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    systemctl enable --now nginx
  EOF
  )

  identity {
    type         = "UserAssigned"
    identity_ids = [var.app_identity_id]
  }

  tags = {
    Name = "${var.app_name}-${var.environment}-app"
  }

  lifecycle {
    ignore_changes = [custom_data]
  }
}
