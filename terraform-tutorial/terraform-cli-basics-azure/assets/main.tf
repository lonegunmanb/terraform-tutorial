terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}

  # miniblue HTTPS metadata endpoint
  metadata_host                   = "localhost:4567"
  resource_provider_registrations = "none"

  # miniblue 接受任意凭据
  subscription_id = "00000000-0000-0000-0000-000000000000"
  tenant_id       = "00000000-0000-0000-0000-000000000001"
  client_id       = "miniblue"
  client_secret   = "miniblue"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "部署环境（dev / staging / prod）"
}

variable "app_name" {
  type        = string
  default     = "myapp"
  description = "应用名称"
}

variable "suffix" {
  type        = string
  default     = "lab"
  description = "资源名称后缀，避免命名冲突"
}

locals {
  name_prefix = "${var.app_name}-${var.environment}"
  common_tags = {
    Environment = var.environment
    App         = var.app_name
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_resource_group" "setup" {
  name     = "${local.name_prefix}-setup-${var.suffix}"
  location = "East US"
  tags     = local.common_tags
}

resource "azurerm_resource_group" "deploy" {
  depends_on = [azurerm_resource_group.setup]

  name     = "${local.name_prefix}-deploy-${var.suffix}"
  location = "East US"
  tags     = local.common_tags
}

output "name_prefix" {
  value       = local.name_prefix
  description = "资源名称前缀"
}

output "setup_rg" {
  value       = azurerm_resource_group.setup.name
  description = "setup 阶段的 Resource Group 名称"
}

output "deploy_rg" {
  value       = azurerm_resource_group.deploy.name
  description = "deploy 阶段的 Resource Group 名称"
}
