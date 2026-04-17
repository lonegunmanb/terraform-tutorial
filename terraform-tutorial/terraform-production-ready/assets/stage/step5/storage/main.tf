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

module "storage" {
  source = "../modules/storage"

  app_name    = local.app_name
  environment = var.environment
}

output "static_bucket_name" {
  value = module.storage.static_bucket_name
}

output "static_bucket_arn" {
  value = module.storage.static_bucket_arn
}

output "backup_bucket_name" {
  value = module.storage.backup_bucket_name
}
