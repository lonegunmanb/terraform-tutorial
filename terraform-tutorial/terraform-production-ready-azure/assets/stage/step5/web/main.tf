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

variable "vnet_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "app_identity_id" {
  type = string
}

locals {
  app_name = "${var.app_name}-${var.suffix}"
}

module "web" {
  source = "../modules/web"

  app_name            = local.app_name
  environment         = var.environment
  resource_group_name = var.resource_group_name
  location            = var.location
  vnet_id             = var.vnet_id
  public_subnet_ids   = var.public_subnet_ids
  private_subnet_ids  = var.private_subnet_ids
  app_identity_id     = var.app_identity_id
}

output "lb_public_ip" {
  value = module.web.lb_public_ip
}
