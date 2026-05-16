variable "app_name" { type = string }
variable "environment" { type = string }
variable "suffix" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }

module "storage" {
  source = "../modules/storage"

  app_name            = var.app_name
  environment         = var.environment
  suffix              = var.suffix
  resource_group_name = var.resource_group_name
  location            = var.location
}

output "storage_account_name" { value = module.storage.storage_account_name }
output "container_name" { value = module.storage.container_name }
