# 网络层：Resource Group、VNet、子网
# 对应三层架构中的网络基础设施——公有子网放 LB，私有子网放应用和数据

resource "azurerm_resource_group" "main" {
  name     = "${var.app_name}-${var.environment}-rg"
  location = var.location

  tags = {
    Environment = var.environment
    App         = var.app_name
  }
}

resource "azurerm_virtual_network" "this" {
  name                = "${var.app_name}-${var.environment}-vnet"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Name = "${var.app_name}-${var.environment}-vnet"
  }
}

resource "azurerm_subnet" "public" {
  for_each = zipmap(var.public_subnet_cidrs, var.availability_zones)

  name                 = "${var.app_name}-${var.environment}-public-${each.value}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [each.key]
}

resource "azurerm_subnet" "private" {
  for_each = zipmap(var.private_subnet_cidrs, var.availability_zones)

  name                 = "${var.app_name}-${var.environment}-private-${each.value}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [each.key]
}
