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

resource "null_resource" "demo" {
  triggers = {
    env = var.environment
  }
}

output "environment" {
  value       = var.environment
  description = "当前部署环境"
}
