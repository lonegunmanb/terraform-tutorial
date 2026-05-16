terraform {
  required_version = ">= 1.5, < 2.0"
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

# ── 网络层 ────────────────────────────────────────────────────────────────
module "networking" {
  source = "./modules/networking"

  app_name    = local.app_name
  environment = var.environment
  vnet_cidr   = var.vnet_cidr
  location    = var.location
}

# ── Web 层 ──────────────────────────────────────────────────────────────
module "web" {
  source = "./modules/web"

  app_name            = local.app_name
  environment         = var.environment
  resource_group_name = module.networking.resource_group_name
  location            = var.location
  vnet_id             = module.networking.vnet_id
  public_subnet_ids   = module.networking.public_subnet_ids
  private_subnet_ids  = module.networking.private_subnet_ids
  web_ssh_public_key  = tls_private_key.web_ssh.public_key_openssh
  app_identity_id     = module.security.app_identity_id
}

# ── 数据层 ────────────────────────────────────────────────────────────────
module "data" {
  source = "./modules/data"

  app_name            = local.app_name
  environment         = var.environment
  resource_group_name = module.networking.resource_group_name
  location            = module.networking.location
}

# ── 存储层 ────────────────────────────────────────────────────────────────
module "storage" {
  source = "./modules/storage"

  app_name            = local.app_name
  environment         = var.environment
  resource_group_name = module.networking.resource_group_name
  location            = module.networking.location
  suffix              = local.suffix
}

# ── 安全层（已提取为模块）─────────────────────────────────────────────────
module "security" {
  source = "./modules/security"

  app_name            = local.app_name
  environment         = var.environment
  resource_group_name = module.networking.resource_group_name
  location            = module.networking.location

  static_storage_account_id = module.storage.static_storage_account_id
  backup_storage_account_id = module.storage.backup_storage_account_id
  cosmos_account_id         = module.data.cosmos_account_id
}

# ══════════════════════════════════════════════════════════════════════════════
# 输出
# ══════════════════════════════════════════════════════════════════════════════

output "resource_group_name" {
  value = module.networking.resource_group_name
}

output "vnet_id" {
  value = module.networking.vnet_id
}

output "lb_public_ip" {
  value = module.web.lb_public_ip
}

output "static_storage_account" {
  value = module.storage.static_storage_account_name
}

output "backup_storage_account" {
  value = module.storage.backup_storage_account_name
}

output "cosmos_account" {
  value = module.data.cosmos_account_name
}

output "app_identity_principal_id" {
  value = module.security.app_identity_principal_id
}
