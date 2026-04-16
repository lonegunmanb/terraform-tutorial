terraform {
  required_version = ">= 1.5, < 2.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
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

module "networking" {
  source = "./modules/networking"

  app_name    = var.app_name
  environment = var.environment
  vpc_cidr    = var.vpc_cidr
}

module "web" {
  source = "./modules/web"

  app_name                = var.app_name
  environment             = var.environment
  vpc_id                  = module.networking.vpc_id
  public_subnet_ids       = module.networking.public_subnet_ids
  private_subnet_ids      = module.networking.private_subnet_ids
  app_instance_profile_name = module.security.app_instance_profile_name
}

module "data" {
  source = "./modules/data"

  app_name    = var.app_name
  environment = var.environment
}

module "storage" {
  source = "./modules/storage"

  app_name    = var.app_name
  environment = var.environment
}

module "security" {
  source = "./modules/security"

  app_name    = var.app_name
  environment = var.environment

  static_bucket_arn = module.storage.static_bucket_arn
  task_queue_arn    = "" # SQS removed
  users_table_arn   = module.data.users_table_arn
  app_config_arn    = aws_ssm_parameter.app_config.arn
  log_group_arn     = aws_cloudwatch_log_group.app.arn
}

resource "aws_ssm_parameter" "app_config" {
  name  = "/${var.app_name}/${var.environment}/config"
  type  = "String"
  value = jsonencode({
    log_level     = "info"
    cache_ttl     = 300
    feature_flags = { new_dashboard = true }
  })
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/${var.app_name}/${var.environment}/app"
  retention_in_days = 30
}
