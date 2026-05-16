include "root" { path = find_in_parent_folders() }

dependency "networking" {
  config_path = "../networking"
  mock_outputs = {
    resource_group_name = "webapp-dev-lab-rg"
    location            = "East US"
    web_subnet_id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/webapp-dev-lab-rg/providers/Microsoft.Network/virtualNetworks/webapp-dev-lab-vnet/subnets/webapp-dev-lab-web"
  }
}

dependency "security" {
  config_path = "../security"
  mock_outputs = {
    web_nsg_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/webapp-dev-lab-rg/providers/Microsoft.Network/networkSecurityGroups/webapp-dev-lab-web-nsg"
  }
}

inputs = {
  resource_group_name = dependency.networking.outputs.resource_group_name
  location            = dependency.networking.outputs.location
  web_subnet_id       = dependency.networking.outputs.web_subnet_id
  web_nsg_id          = dependency.security.outputs.web_nsg_id
}
