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

dependency "storage" {
  config_path = "../storage"
  mock_outputs = {
    static_storage_account_id = "/subscriptions/mock/resourceGroups/mock-rg/providers/Microsoft.Storage/storageAccounts/mockstatic"
    backup_storage_account_id = "/subscriptions/mock/resourceGroups/mock-rg/providers/Microsoft.Storage/storageAccounts/mockbackups"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "data" {
  config_path = "../data"
  mock_outputs = {
    cosmos_account_id = "/subscriptions/mock/resourceGroups/mock-rg/providers/Microsoft.DocumentDB/databaseAccounts/mockcosmos"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

inputs = {
  resource_group_name       = dependency.networking.outputs.resource_group_name
  location                  = dependency.networking.outputs.location
  static_storage_account_id = dependency.storage.outputs.static_storage_account_id
  backup_storage_account_id = dependency.storage.outputs.backup_storage_account_id
  cosmos_account_id         = dependency.data.outputs.cosmos_account_id
}
