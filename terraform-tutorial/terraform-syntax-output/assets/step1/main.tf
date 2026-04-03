# ==============================
# Terraform 输出值示例：基础与 description
# ==============================

# ── 基础输出值 ──

locals {
  project     = "my-app"
  environment = "dev"
  version     = "1.2.3"
}

# 最简单的输出值：只有 value
output "project_name" {
  value = local.project
}

# 带 description 的输出值
output "environment" {
  value       = local.environment
  description = "The deployment environment name."
}

output "app_version" {
  value       = local.version
  description = "The current application version."
}

# ── 输出表达式的结果 ──

# 输出值可以是任意合法的表达式
output "full_name" {
  value       = "${local.project}-${local.environment}"
  description = "The full application identifier (project-environment)."
}

# 输出复合类型
output "app_info" {
  value = {
    project     = local.project
    environment = local.environment
    version     = local.version
    full_name   = "${local.project}-${local.environment}"
  }
  description = "Complete application metadata as an object."
}

# 输出列表
variable "allowed_cidrs" {
  type    = list(string)
  default = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

output "allowed_cidrs" {
  value       = var.allowed_cidrs
  description = "List of allowed CIDR blocks for network access."
}

# 输出计算结果
output "cidr_count" {
  value       = length(var.allowed_cidrs)
  description = "Number of allowed CIDR blocks."
}

# ── 多输出值 ──
# Terraform 支持在同一模块中定义多个输出值（多返回值）
# apply 成功后，所有输出值都会显示在命令行中
