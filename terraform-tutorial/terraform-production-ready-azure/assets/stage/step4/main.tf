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

module "security" {
  source = "./modules/security"

  app_name            = var.app_name
  environment         = var.environment
  suffix              = var.suffix
  resource_group_name = module.networking.resource_group_name
  location            = module.networking.location
}

module "web" {
  source = "./modules/web"

  app_name            = var.app_name
  environment         = var.environment
  suffix              = var.suffix
  resource_group_name = module.networking.resource_group_name
  location            = module.networking.location
  web_subnet_id       = module.networking.web_subnet_id
  web_nsg_id          = module.security.web_nsg_id
}

module "storage" {
  source = "./modules/storage"

  app_name            = var.app_name
  environment         = var.environment
  suffix              = var.suffix
  resource_group_name = module.networking.resource_group_name
  location            = module.networking.location
}

module "dns" {
  source = "./modules/dns"

  app_name            = var.app_name
  environment         = var.environment
  suffix              = var.suffix
  resource_group_name = module.networking.resource_group_name
}

output "resource_group_name" { value = module.networking.resource_group_name }
output "vnet_name" { value = module.networking.vnet_name }
output "web_vm_name" { value = module.web.web_vm_name }
output "storage_account_name" { value = module.storage.storage_account_name }
output "dns_zone_name" { value = module.dns.dns_zone_name }
