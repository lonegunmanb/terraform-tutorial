variable "app_name" { type = string }
variable "environment" { type = string }
variable "suffix" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "web_subnet_id" { type = string }
variable "web_nsg_id" { type = string }

module "web" {
  source = "../modules/web"

  app_name            = var.app_name
  environment         = var.environment
  suffix              = var.suffix
  resource_group_name = var.resource_group_name
  location            = var.location
  web_subnet_id       = var.web_subnet_id
  web_nsg_id          = var.web_nsg_id
}

output "web_vm_name" { value = module.web.web_vm_name }
output "web_private_ip" { value = module.web.web_private_ip }
