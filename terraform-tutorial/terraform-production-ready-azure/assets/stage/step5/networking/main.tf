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

variable "vnet_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "location" {
  type    = string
  default = "East US"
}

locals {
  app_name = "${var.app_name}-${var.suffix}"
}

module "networking" {
  source = "../modules/networking"

  app_name    = local.app_name
  environment = var.environment
  vnet_cidr   = var.vnet_cidr
  location    = var.location
}

output "resource_group_name" {
  value = module.networking.resource_group_name
}

output "location" {
  value = module.networking.location
}

output "vnet_id" {
  value = module.networking.vnet_id
}

output "public_subnet_ids" {
  value = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.networking.private_subnet_ids
}
