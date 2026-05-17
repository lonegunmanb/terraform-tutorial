# ──────────────────────────────────────────────────────────────────────────────
# step1/main.tf
# 反模式示例：三层 Web 架构的所有资源挤在单个文件里
# 网络、负载均衡、数据、存储、安全、身份——全部混在一起
# ──────────────────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

locals {
  suffix   = "lab"
  app_name = "${var.app_name}-${local.suffix}"
  # Azure storage account names: 3-24 chars, lowercase alphanumeric only
  storage_name_static  = substr(replace("${var.app_name}${var.environment}static${local.suffix}", "-", ""), 0, 24)
  storage_name_backups = substr(replace("${var.app_name}${var.environment}backups${local.suffix}", "-", ""), 0, 24)
}

resource "tls_private_key" "web_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

provider "azurerm" {
  features {}

  metadata_host                   = "localhost:4567"
  resource_provider_registrations = "none"

  subscription_id = "00000000-0000-0000-0000-000000000000"
  tenant_id       = "00000000-0000-0000-0000-000000000001"
  client_id       = "miniblue"
  client_secret   = "miniblue"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "app_name" {
  type    = string
  default = "webapp"
}

variable "vnet_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "location" {
  type    = string
  default = "East US"
}

# ══════════════════════════════════════════════════════════════════════════════
# 资源组
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_resource_group" "main" {
  name     = "${local.app_name}-${var.environment}-rg"
  location = var.location

  tags = {
    Environment = var.environment
    App         = local.app_name
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# 网络层
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_virtual_network" "main" {
  name                = "${local.app_name}-${var.environment}-vnet"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Name = "${local.app_name}-${var.environment}-vnet"
  }
}

resource "azurerm_subnet" "public_a" {
  name                 = "${local.app_name}-${var.environment}-public-a"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "public_b" {
  name                 = "${local.app_name}-${var.environment}-public-b"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "private_a" {
  name                 = "${local.app_name}-${var.environment}-private-a"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.11.0/24"]
}

resource "azurerm_subnet" "private_b" {
  name                 = "${local.app_name}-${var.environment}-private-b"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.12.0/24"]
}

# ══════════════════════════════════════════════════════════════════════════════
# 网络安全组
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_network_security_group" "lb" {
  name                = "${local.app_name}-${var.environment}-lb-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

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
    Name = "${local.app_name}-${var.environment}-lb-nsg"
  }

  lifecycle {
    ignore_changes = [security_rule]
  }
}

resource "azurerm_network_security_group" "app" {
  name                = "${local.app_name}-${var.environment}-app-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

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
    Name = "${local.app_name}-${var.environment}-app-nsg"
  }

  lifecycle {
    ignore_changes = [security_rule]
  }
}

resource "azurerm_network_security_group" "data" {
  name                = "${local.app_name}-${var.environment}-data-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

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
    Name = "${local.app_name}-${var.environment}-data-nsg"
  }

  lifecycle {
    ignore_changes = [security_rule]
  }
}

resource "azurerm_subnet_network_security_group_association" "public_a" {
  subnet_id                 = azurerm_subnet.public_a.id
  network_security_group_id = azurerm_network_security_group.lb.id
}

resource "azurerm_subnet_network_security_group_association" "public_b" {
  subnet_id                 = azurerm_subnet.public_b.id
  network_security_group_id = azurerm_network_security_group.lb.id
}

resource "azurerm_subnet_network_security_group_association" "private_a" {
  subnet_id                 = azurerm_subnet.private_a.id
  network_security_group_id = azurerm_network_security_group.app.id
}

resource "azurerm_subnet_network_security_group_association" "private_b" {
  subnet_id                 = azurerm_subnet.private_b.id
  network_security_group_id = azurerm_network_security_group.app.id
}

# ══════════════════════════════════════════════════════════════════════════════
# Web 层：负载均衡
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_public_ip" "lb" {
  name                = "${local.app_name}-${var.environment}-lb-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Name = "${local.app_name}-${var.environment}-lb-pip"
  }
}

resource "azurerm_lb" "web" {
  name                = "${local.app_name}-${var.environment}-lb"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "frontend"
    public_ip_address_id = azurerm_public_ip.lb.id
  }

  tags = {
    Name = "${local.app_name}-${var.environment}-lb"
  }
}

resource "azurerm_lb_backend_address_pool" "app" {
  name            = "${local.app_name}-${var.environment}-backend"
  loadbalancer_id = azurerm_lb.web.id
}

resource "azurerm_lb_probe" "http" {
  name                = "http-probe"
  loadbalancer_id     = azurerm_lb.web.id
  protocol            = "Http"
  port                = 80
  request_path        = "/"
  interval_in_seconds = 15
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "http" {
  name                           = "http-rule"
  loadbalancer_id                = azurerm_lb.web.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.app.id]
  probe_id                       = azurerm_lb_probe.http.id
}

# ══════════════════════════════════════════════════════════════════════════════
# Web 层：VM 计算
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_network_interface" "app" {
  name                = "${local.app_name}-${var.environment}-app-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.private_a.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    Name = "${local.app_name}-${var.environment}-app-nic"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "app" {
  network_interface_id    = azurerm_network_interface.app.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.app.id
}

resource "azurerm_linux_virtual_machine" "app" {
  name                            = "${local.app_name}-${var.environment}-app-vm"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = "Standard_B1s"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.web_ssh.public_key_openssh
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
    identity_ids = [azurerm_user_assigned_identity.app.id]
  }

  tags = {
    Name = "${local.app_name}-${var.environment}-app"
  }

  lifecycle {
    ignore_changes = [custom_data]
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# 数据层
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_cosmosdb_account" "users" {
  name                = "${local.app_name}-${var.environment}-cosmos"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.main.location
    failover_priority = 0
  }

  capabilities {
    name = "EnableTable"
  }

  tags = {
    Name = "${local.app_name}-${var.environment}-cosmos"
  }
}

resource "azurerm_cosmosdb_table" "users" {
  name                = "users"
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.users.name
}

# ══════════════════════════════════════════════════════════════════════════════
# 存储层
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_storage_account" "static" {
  name                     = local.storage_name_static
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  blob_properties {
    versioning_enabled = true
  }

  tags = {
    Name = "${local.app_name}-${var.environment}-static"
  }
}

resource "azurerm_storage_container" "static" {
  name                  = "static"
  storage_account_id    = azurerm_storage_account.static.id
  container_access_type = "private"
}

resource "azurerm_storage_account" "backups" {
  name                     = local.storage_name_backups
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  blob_properties {
    versioning_enabled = true
  }

  tags = {
    Name = "${local.app_name}-${var.environment}-backups"
  }
}

resource "azurerm_storage_container" "backups" {
  name                  = "backups"
  storage_account_id    = azurerm_storage_account.backups.id
  container_access_type = "private"
}

resource "azurerm_storage_management_policy" "backups" {
  storage_account_id = azurerm_storage_account.backups.id

  rule {
    name    = "expire-old-backups"
    enabled = true
    filters {
      blob_types = ["blockBlob"]
    }
    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = 90
      }
    }
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# 安全与配置
# ══════════════════════════════════════════════════════════════════════════════

data "azurerm_client_config" "current" {}

resource "azurerm_user_assigned_identity" "app" {
  name                = "${local.app_name}-${var.environment}-app-identity"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  tags = {
    Name = "${local.app_name}-${var.environment}-app-identity"
  }
}

resource "azurerm_role_assignment" "storage_static" {
  scope                = azurerm_storage_account.static.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

resource "azurerm_role_assignment" "storage_backups" {
  scope                = azurerm_storage_account.backups.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

resource "azurerm_role_assignment" "cosmos" {
  scope                = azurerm_cosmosdb_account.users.id
  role_definition_name = "Cosmos DB Account Reader Role"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

resource "azurerm_key_vault" "app" {
  name                       = substr("${local.app_name}-${var.environment}-kv", 0, 24)
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  rbac_authorization_enabled = true


  tags = {
    Name = "${local.app_name}-${var.environment}-kv"
  }
}

resource "azurerm_key_vault_secret" "db_credentials" {
  name = "db-credentials"
  value = jsonencode({
    username = "app_user"
    password = "change-me-in-production"
    host     = "db.internal"
    port     = 5432
  })
  key_vault_id = azurerm_key_vault.app.id
}

resource "azurerm_app_configuration" "app" {
  name                = "${local.app_name}-${var.environment}-appconfig"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "free"

  tags = {
    Name = "${local.app_name}-${var.environment}-appconfig"
  }
}

resource "azurerm_role_assignment" "appconfig" {
  scope                = azurerm_app_configuration.app.id
  role_definition_name = "App Configuration Data Reader"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

resource "azurerm_role_assignment" "keyvault" {
  scope                = azurerm_key_vault.app.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

# ══════════════════════════════════════════════════════════════════════════════
# 输出
# ══════════════════════════════════════════════════════════════════════════════

output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "vnet_id" {
  value = azurerm_virtual_network.main.id
}

output "lb_public_ip" {
  value = azurerm_public_ip.lb.ip_address
}

output "static_storage_account" {
  value = azurerm_storage_account.static.name
}

output "backup_storage_account" {
  value = azurerm_storage_account.backups.name
}

output "cosmos_account" {
  value = azurerm_cosmosdb_account.users.name
}

output "app_identity_principal_id" {
  value = azurerm_user_assigned_identity.app.principal_id
}
