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

module "data" {
  source = "../modules/data"

  app_name            = local.app_name
  environment         = var.environment
  resource_group_name = var.resource_group_name
  location            = var.location
}

output "cosmos_account_name" {
  value = module.data.cosmos_account_name
}

output "cosmos_account_id" {
  value = module.data.cosmos_account_id
}
