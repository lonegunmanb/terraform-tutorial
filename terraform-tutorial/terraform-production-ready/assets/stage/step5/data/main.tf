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

locals {
  app_name = "${var.app_name}-${var.suffix}"
}

module "data" {
  source = "../modules/data"

  app_name    = local.app_name
  environment = var.environment
}

output "users_table_name" {
  value = module.data.users_table_name
}

output "users_table_arn" {
  value = module.data.users_table_arn
}
