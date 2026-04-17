locals {
  suffix      = "REPLACE_ME" # 从 terraform state 中提取的 random_string 值
  app_name    = "webapp"
  environment = "dev"
  vpc_cidr    = "10.0.0.0/16"
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
    provider "aws" {
      region     = "us-east-1"
      access_key = "test"
      secret_key = "test"

      skip_credentials_validation = true
      skip_metadata_api_check     = true
      skip_requesting_account_id  = true
      s3_use_path_style           = true

      endpoints {
        s3             = "http://localhost:4566"
        sqs            = "http://localhost:4566"
        sns            = "http://localhost:4566"
        dynamodb       = "http://localhost:4566"
        iam            = "http://localhost:4566"
        sts            = "http://localhost:4566"
        secretsmanager = "http://localhost:4566"
        ssm            = "http://localhost:4566"
        cloudwatchlogs = "http://localhost:4566"
        ec2            = "http://localhost:4566"
        elbv2          = "http://localhost:4566"
      }
    }
  EOF
}

inputs = {
  suffix      = local.suffix
  app_name    = local.app_name
  environment = local.environment
  vpc_cidr    = local.vpc_cidr
}
