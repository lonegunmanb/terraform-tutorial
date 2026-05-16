terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
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

variable "suffix" {
  type    = string
  default = "lab"
}

variable "location" {
  type    = string
  default = "East US"
}

variable "vnet_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

locals {
  name_prefix = "${var.app_name}-${var.environment}-${var.suffix}"
  common_tags = {
    App         = var.app_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

module "networking" {
  source = "./modules/networking"

  app_name    = var.app_name
  environment = var.environment
  suffix      = var.suffix
  location    = var.location
  vnet_cidr   = var.vnet_cidr
}

resource "azurerm_network_security_group" "web" {
  name                = "${local.name_prefix}-web-nsg"
  location            = module.networking.location
  resource_group_name = module.networking.resource_group_name

  security_rule {
    name                       = "AllowHttp"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

resource "azurerm_network_security_group" "app" {
  name                = "${local.name_prefix}-app-nsg"
  location            = module.networking.location
  resource_group_name = module.networking.resource_group_name

  security_rule {
    name                       = "AllowWeb"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

resource "azurerm_network_security_group" "data" {
  name                = "${local.name_prefix}-data-nsg"
  location            = module.networking.location
  resource_group_name = module.networking.resource_group_name

  security_rule {
    name                       = "AllowApp"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "10.0.2.0/24"
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

module "web" {
  source = "./modules/web"

  app_name            = var.app_name
  environment         = var.environment
  suffix              = var.suffix
  resource_group_name = module.networking.resource_group_name
  location            = module.networking.location
  web_subnet_id       = module.networking.web_subnet_id
  web_nsg_id          = azurerm_network_security_group.web.id
}

resource "azurerm_storage_account" "assets" {
  name                     = "${var.app_name}${var.environment}${var.suffix}assets"
  resource_group_name      = module.networking.resource_group_name
  location                 = module.networking.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.common_tags
}

resource "azurerm_storage_container" "assets" {
  name                  = "static-assets"
  storage_account_id    = azurerm_storage_account.assets.id
  container_access_type = "private"
}

resource "azurerm_dns_zone" "app" {
  name                = "${local.name_prefix}.local"
  resource_group_name = module.networking.resource_group_name
  tags                = local.common_tags
}

output "resource_group_name" { value = module.networking.resource_group_name }
output "vnet_name" { value = module.networking.vnet_name }
output "web_vm_name" { value = module.web.web_vm_name }
output "storage_account_name" { value = azurerm_storage_account.assets.name }
output "dns_zone_name" { value = azurerm_dns_zone.app.name }
