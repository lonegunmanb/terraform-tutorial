terraform {
  required_version = ">= 1.0"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "部署环境（dev / staging / prod）"
}

variable "app_name" {
  type        = string
  default     = "my-app"
  description = "应用名称"
}

locals {
  name_prefix = "${var.app_name}-${var.environment}"
  common_tags = {
    Environment = var.environment
    App         = var.app_name
  }
}

resource "null_resource" "setup" {
  triggers = {
    name = local.name_prefix
  }
}

resource "null_resource" "deploy" {
  depends_on = [null_resource.setup]

  triggers = {
    env = var.environment
  }
}

output "name_prefix" {
  value       = local.name_prefix
  description = "资源名称前缀"
}
