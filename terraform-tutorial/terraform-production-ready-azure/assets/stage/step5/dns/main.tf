variable "app_name" { type = string }
variable "environment" { type = string }
variable "suffix" { type = string }
variable "resource_group_name" { type = string }

module "dns" {
  source = "../modules/dns"

  app_name            = var.app_name
  environment         = var.environment
  suffix              = var.suffix
  resource_group_name = var.resource_group_name
}

output "dns_zone_name" { value = module.dns.dns_zone_name }
