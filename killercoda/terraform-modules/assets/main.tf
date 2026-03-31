terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = "test"
  secret_key = "test"

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3  = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}

# Call the s3-bucket module to create an "app data" bucket
module "app_data" {
  source = "./modules/s3-bucket"

  bucket_name = "my-app-data"
  environment = "dev"

  tags = {
    Team = "backend"
  }
}

# TODO: Uncomment to create a second bucket using the same module
# module "app_logs" {
#   source = "./modules/s3-bucket"
#
#   bucket_name = "my-app-logs"
#   environment = "dev"
#
#   tags = {
#     Team = "platform"
#   }
# }

output "data_bucket_id" {
  value = module.app_data.bucket_id
}

# output "logs_bucket_id" {
#   value = module.app_logs.bucket_id
# }
