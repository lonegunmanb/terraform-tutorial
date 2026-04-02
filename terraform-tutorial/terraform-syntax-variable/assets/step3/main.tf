# ==============================
# Terraform 输入变量：敏感值与临时变量
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

# ── 普通变量（用于演示 sensitive 在表达式中的传播）──
variable "app_name" {
  type        = string
  default     = "default-app"
  description = "应用名称"
}

# ── ephemeral 临时变量（Terraform >= 1.10）──
variable "session_token" {
  type        = string
  default     = "tok-temp-abc123"
  ephemeral   = true
  description = "临时会话令牌（不会记录到状态文件和计划文件中）"
}

locals {
  # sensitive 变量参与的表达式也会被标记为 sensitive
  connection_string = "postgres://admin:${var.db_password}@db.${var.region}.example.com"
  # ephemeral 变量可以在 locals 中引用
  auth_header       = "Bearer ${var.session_token}"
  app_label         = "${var.app_name}-${var.region}"
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

output "connection_string" {
  value     = local.connection_string
  sensitive = true
}

output "app_label" {
  value = local.app_label
}

output "auth_header" {
  value     = local.auth_header
  ephemeral = true
}
