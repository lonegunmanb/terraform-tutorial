include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

dependency "networking" {
  config_path = "../networking"
  mock_outputs = {
    vpc_id             = "vpc-mock"
    public_subnet_ids  = ["subnet-mock-1", "subnet-mock-2"]
    private_subnet_ids = ["subnet-mock-3", "subnet-mock-4"]
  }
}

dependency "security" {
  config_path = "../security"
  mock_outputs = {
    app_instance_profile_name = "mock-profile"
  }
}

inputs = {
  vpc_id                    = dependency.networking.outputs.vpc_id
  public_subnet_ids         = dependency.networking.outputs.public_subnet_ids
  private_subnet_ids        = dependency.networking.outputs.private_subnet_ids
  app_instance_profile_name = dependency.security.outputs.app_instance_profile_name
}
