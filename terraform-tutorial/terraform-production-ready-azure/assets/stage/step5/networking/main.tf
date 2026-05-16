variable "app_name" { type = string }
variable "environment" { type = string }
variable "suffix" { type = string }
variable "location" { type = string }
variable "vnet_cidr" { type = string }

module "networking" {
  source = "../modules/networking"

  app_name    = var.app_name
  environment = var.environment
  suffix      = var.suffix
  location    = var.location
  vnet_cidr   = var.vnet_cidr
}

output "resource_group_name" { value = module.networking.resource_group_name }
output "location" { value = module.networking.location }
output "vnet_name" { value = module.networking.vnet_name }
output "web_subnet_id" { value = module.networking.web_subnet_id }
output "app_subnet_id" { value = module.networking.app_subnet_id }
output "data_subnet_id" { value = module.networking.data_subnet_id }
