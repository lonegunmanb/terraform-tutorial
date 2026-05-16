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

resource "tls_private_key" "web_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
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
  web_ssh_public_key  = tls_private_key.web_ssh.public_key_openssh
  app_identity_id     = var.app_identity_id
}

output "lb_public_ip" {
  value = module.web.lb_public_ip
}
