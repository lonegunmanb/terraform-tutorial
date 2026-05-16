include "root" { path = find_in_parent_folders() }

dependency "networking" {
  config_path = "../networking"
  mock_outputs = {
    resource_group_name = "webapp-dev-lab-rg"
    location            = "East US"
  }
}

inputs = {
  resource_group_name = dependency.networking.outputs.resource_group_name
  location            = dependency.networking.outputs.location
}
