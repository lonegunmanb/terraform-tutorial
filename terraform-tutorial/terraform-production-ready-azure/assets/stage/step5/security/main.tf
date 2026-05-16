terraform {
  required_version = ">= 1.5, < 2.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

variable "suffix" {
  type = string
}

variable "app_name" {
  type    = string
  default = "webapp"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "static_storage_account_id" {
  type = string
}

variable "backup_storage_account_id" {
  type = string
}

variable "cosmos_account_id" {
  type = string
}

locals {
  app_name = "${var.app_name}-${var.suffix}"
}

module "security" {
  source = "../modules/security"

  app_name            = local.app_name
  environment         = var.environment
  resource_group_name = var.resource_group_name
  location            = var.location

  static_storage_account_id = var.static_storage_account_id
  backup_storage_account_id = var.backup_storage_account_id
  cosmos_account_id         = var.cosmos_account_id
}

output "app_identity_id" {
  value = module.security.app_identity_id
}

output "app_identity_principal_id" {
  value = module.security.app_identity_principal_id
}

output "key_vault_name" {
  value = module.security.key_vault_name
}

output "db_credentials_secret_name" {
  value = module.security.db_credentials_secret_name
}
