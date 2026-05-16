include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

dependency "networking" {
  config_path = "../networking"
  mock_outputs = {
    resource_group_name = "mock-rg"
    location            = "East US"
    vnet_id             = "/subscriptions/mock/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet"
    public_subnet_ids   = ["/subscriptions/mock/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet/subnets/mock-1", "/subscriptions/mock/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet/subnets/mock-2"]
    private_subnet_ids  = ["/subscriptions/mock/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet/subnets/mock-3", "/subscriptions/mock/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet/subnets/mock-4"]
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "security" {
  config_path = "../security"
  mock_outputs = {
    app_identity_id = "/subscriptions/mock/resourceGroups/mock-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mock-identity"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

inputs = {
  resource_group_name = dependency.networking.outputs.resource_group_name
  location            = dependency.networking.outputs.location
  vnet_id             = dependency.networking.outputs.vnet_id
  public_subnet_ids   = dependency.networking.outputs.public_subnet_ids
  private_subnet_ids  = dependency.networking.outputs.private_subnet_ids
  app_identity_id     = dependency.security.outputs.app_identity_id
}
