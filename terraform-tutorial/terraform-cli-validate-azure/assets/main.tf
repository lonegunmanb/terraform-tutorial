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
  description = "部署环境"
}

variable "app_name" {
  type        = string
  default     = "myapp"
  description = "应用名称"
}

variable "suffix" {
  type        = string
  default     = "lab"
  description = "资源名称后缀，用于避免命名冲突"
}

resource "azurerm_resource_group" "main" {
  name     = "${var.app_name}-${var.environment}-rg-${var.suffix}"
  location = "East US"
  tags = {
    Environment = var.environment
    App         = var.app_name
    ManagedBy   = "Terraform"
  }
}

output "resource_group" {
  value = azurerm_resource_group.main.name
}
