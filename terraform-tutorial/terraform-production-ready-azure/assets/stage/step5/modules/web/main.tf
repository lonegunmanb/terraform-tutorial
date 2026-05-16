locals {
  name_prefix = "${var.app_name}-${var.environment}-${var.suffix}"
  common_tags = {
    App         = var.app_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_public_ip" "web" {
  name                = "${local.name_prefix}-web-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  tags                = local.common_tags
}

resource "azurerm_network_interface" "web" {
  name                = "${local.name_prefix}-web-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = var.web_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web.id
  }

  tags = local.common_tags
}

resource "azurerm_network_interface_security_group_association" "web" {
  network_interface_id      = azurerm_network_interface.web.id
  network_security_group_id = var.web_nsg_id
}

resource "azurerm_linux_virtual_machine" "web" {
  name                            = "${local.name_prefix}-web-vm"
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = var.vm_size
  admin_username                  = "azureuser"
  admin_password                  = "Password1234!"
  disable_password_authentication = false
  network_interface_ids          = [azurerm_network_interface.web.id]

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

  lifecycle {
    precondition {
      condition     = contains(["Standard_B1s", "Standard_B2s"], var.vm_size)
      error_message = "教程环境只允许使用 Standard_B1s 或 Standard_B2s，避免占用过多模拟器资源。"
    }
  }

  tags = local.common_tags
}
