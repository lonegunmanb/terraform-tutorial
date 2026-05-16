include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

dependency "networking" {
  config_path = "../networking"
  mock_outputs = {
    resource_group_name = "mock-rg"
    location            = "East US"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

inputs = {
  resource_group_name = dependency.networking.outputs.resource_group_name
  location            = dependency.networking.outputs.location
}
