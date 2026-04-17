terraform {
  required_version = ">= 1.5, < 2.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

variable "suffix" {
  type = string
}

variable "app_name" {
  type    = string
  default = "webapp"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "static_bucket_arn" {
  type = string
}

variable "users_table_arn" {
  type = string
}

locals {
  app_name = "${var.app_name}-${var.suffix}"
}

module "security" {
  source = "../modules/security"

  app_name    = local.app_name
  environment = var.environment

  static_bucket_arn = var.static_bucket_arn
  users_table_arn   = var.users_table_arn
  app_config_arn    = aws_ssm_parameter.app_config.arn
  log_group_arn     = aws_cloudwatch_log_group.app.arn
}

resource "aws_ssm_parameter" "app_config" {
  name  = "/${local.app_name}/${var.environment}/config"
  type  = "String"
  value = jsonencode({
    log_level     = "info"
    cache_ttl     = 300
    feature_flags = { new_dashboard = true }
  })
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/${local.app_name}/${var.environment}/app"
  retention_in_days = 30
}

output "app_role_arn" {
  value = module.security.app_role_arn
}

output "app_instance_profile_name" {
  value = module.security.app_instance_profile_name
}
