# ==============================
# Terraform 配置语法示例：块与参数
# ==============================

# ── terraform 块：无标签 ──
terraform {
  required_version = ">= 1.0"
}

# ── locals 块：无标签，定义局部变量 ──
# Terraform 允许定义多个 locals 块，但所有块中的 key 必须唯一
locals {
  # 参数赋值：名称 = 值
  project = "my-app"
  region  = "us-east-1"

  # 不同类型的值
  enabled = true
  count   = 3
}

# ── 可以定义多个 locals 块，按用途分组 ──
locals {
  # Map 类型
  tags = {
    Environment = "dev"
    Team        = "platform"
  }

  # List 类型
  zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# ── output 块：一个标签（输出名称）──
output "project" {
  value       = local.project
  description = "项目名称"
}

output "tags" {
  value = local.tags
}

output "zones" {
  value = local.zones
}
