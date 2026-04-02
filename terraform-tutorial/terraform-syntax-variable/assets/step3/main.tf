# ==============================
# Terraform 输入变量：敏感值与赋值
# ==============================

# ── sensitive 变量 ──
variable "db_password" {
  type        = string
  default     = "super-secret-123"
  sensitive   = true
  description = "数据库密码（敏感值，plan/apply 输出中会被隐藏）"
}

# ── nullable = false ──
variable "region" {
  type        = string
  default     = "us-east-1"
  nullable    = false
  description = "部署区域，不允许为 null"
}

# ── 用于演示赋值方式的变量 ──
variable "app_name" {
  type        = string
  default     = "default-app"
  description = "应用名称（可通过 -var、.tfvars 或环境变量赋值）"
}

variable "replica_count" {
  type        = number
  default     = 1
  description = "副本数量"
}

# ── ephemeral 临时变量（Terraform >= 1.10）──
variable "session_token" {
  type        = string
  default     = "tok-temp-abc123"
  ephemeral   = true
  description = "临时会话令牌（不会记录到状态文件和计划文件中）"
}

locals {
  deployment_label = "${var.app_name}-${var.region}-x${var.replica_count}"
  # ephemeral 变量可以在 locals 中引用
  auth_header      = "Bearer ${var.session_token}"
}

output "db_password" {
  value     = var.db_password
  sensitive = true
}

output "region" {
  value = var.region
}

output "app_name" {
  value = var.app_name
}

output "replica_count" {
  value = var.replica_count
}

output "deployment_label" {
  value = local.deployment_label
}

output "auth_header" {
  value     = local.auth_header
  ephemeral = true
}
