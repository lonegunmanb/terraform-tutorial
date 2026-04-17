include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

dependency "networking" {
  config_path = "../networking"
}

dependency "security" {
  config_path = "../security"
}

inputs = {
  vpc_id                    = dependency.networking.outputs.vpc_id
  public_subnet_ids         = dependency.networking.outputs.public_subnet_ids
  private_subnet_ids        = dependency.networking.outputs.private_subnet_ids
  app_instance_profile_name = dependency.security.outputs.app_instance_profile_name
}
