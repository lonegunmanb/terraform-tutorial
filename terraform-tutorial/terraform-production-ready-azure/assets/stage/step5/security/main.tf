variable "app_name" { type = string }
variable "environment" { type = string }
variable "suffix" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }

module "security" {
  source = "../modules/security"

  app_name            = var.app_name
  environment         = var.environment
  suffix              = var.suffix
  resource_group_name = var.resource_group_name
  location            = var.location
}

output "web_nsg_id" { value = module.security.web_nsg_id }
output "app_nsg_id" { value = module.security.app_nsg_id }
output "data_nsg_id" { value = module.security.data_nsg_id }
