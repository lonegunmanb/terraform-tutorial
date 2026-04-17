terraform {
  required_version = ">= 1.5, < 2.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
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

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "app_instance_profile_name" {
  type = string
}

locals {
  app_name = "${var.app_name}-${var.suffix}"
}

module "web" {
  source = "../modules/web"

  app_name                  = local.app_name
  environment               = var.environment
  vpc_id                    = var.vpc_id
  public_subnet_ids         = var.public_subnet_ids
  private_subnet_ids        = var.private_subnet_ids
  app_instance_profile_name = var.app_instance_profile_name
}

output "alb_dns_name" {
  value = module.web.alb_dns_name
}
