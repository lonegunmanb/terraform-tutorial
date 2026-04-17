include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

dependency "storage" {
  config_path = "../storage"
  mock_outputs = {
    static_bucket_arn = "arn:aws:s3:::mock"
  }
}

dependency "data" {
  config_path = "../data"
  mock_outputs = {
    users_table_arn = "arn:aws:dynamodb:us-east-1:000000000000:table/mock"
  }
}

inputs = {
  static_bucket_arn = dependency.storage.outputs.static_bucket_arn
  users_table_arn   = dependency.data.outputs.users_table_arn
}
