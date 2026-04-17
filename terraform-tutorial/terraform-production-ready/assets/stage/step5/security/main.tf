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

variable "static_bucket_arn" {
  type = string
}

variable "users_table_arn" {
  type = string
}

locals {
  app_name = "${var.app_name}-${var.suffix}"
}

module "security" {
  source = "../modules/security"

  app_name    = local.app_name
  environment = var.environment

  static_bucket_arn = var.static_bucket_arn
  users_table_arn   = var.users_table_arn
}

output "app_role_arn" {
  value = module.security.app_role_arn
}

output "app_instance_profile_name" {
  value = module.security.app_instance_profile_name
}
