# 正确的写法：声明了 required_providers
# 对比 step1/main.tf，注意多出的 terraform 块

terraform {
  required_version = ">= 1.0"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

resource "null_resource" "demo" {
  triggers = {
    message = "Hello from Terraform!"
  }
}

output "resource_id" {
  value       = null_resource.demo.id
  description = "null_resource 的 ID"
}
