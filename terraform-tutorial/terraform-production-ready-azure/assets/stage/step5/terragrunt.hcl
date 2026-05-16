locals {
  suffix      = "lab"
  app_name    = "webapp"
  environment = "dev"
  vnet_cidr   = "10.0.0.0/16"
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
    provider "azurerm" {
      features {}

      metadata_host                   = "localhost:4567"
      resource_provider_registrations = "none"

      subscription_id = "00000000-0000-0000-0000-000000000000"
      tenant_id       = "00000000-0000-0000-0000-000000000001"
      client_id       = "miniblue"
      client_secret   = "miniblue"
    }
  EOF
}

inputs = {
  suffix      = local.suffix
  app_name    = local.app_name
  environment = local.environment
  vnet_cidr   = local.vnet_cidr
}
