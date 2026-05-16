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

locals {
  app_name = "${var.app_name}-${var.suffix}"
}

module "storage" {
  source = "../modules/storage"

  app_name            = local.app_name
  environment         = var.environment
  resource_group_name = var.resource_group_name
  location            = var.location
  suffix              = var.suffix
}

output "static_storage_account_name" {
  value = module.storage.static_storage_account_name
}

output "static_storage_account_id" {
  value = module.storage.static_storage_account_id
}

output "backup_storage_account_name" {
  value = module.storage.backup_storage_account_name
}

output "backup_storage_account_id" {
  value = module.storage.backup_storage_account_id
}
