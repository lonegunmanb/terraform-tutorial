# ==============================
# Terraform 输入变量：敏感值与临时资源
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

# ── 普通变量 ──
variable "app_name" {
  type        = string
  default     = "default-app"
  description = "应用名称"
}

# ══════════════════════════════════════════
# 对比：sensitive 资源 vs ephemeral 资源
# ══════════════════════════════════════════

# ── 方式 A：用普通资源存储密码 ──
# secret_string 会以明文写入状态文件
resource "aws_secretsmanager_secret" "sensitive_demo" {
  name                    = "sensitive_demo_password"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "sensitive_demo" {
  secret_id     = aws_secretsmanager_secret.sensitive_demo.id
  secret_string = var.db_password
}

# ── 方式 B：用 ephemeral 资源 + write-only 属性 ──
# 密码由 ephemeral 随机生成，不写入状态文件
ephemeral "random_password" "db_password" {
  length           = 16
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "ephemeral_demo" {
  name                    = "ephemeral_demo_password"
  recovery_window_in_days = 0
}

# secret_string_wo 是 write-only 属性：值会发送到 API，但不会记录在状态中
resource "aws_secretsmanager_secret_version" "ephemeral_demo" {
  secret_id                = aws_secretsmanager_secret.ephemeral_demo.id
  secret_string_wo         = ephemeral.random_password.db_password.result
  secret_string_wo_version = 1
}

# 用 ephemeral 资源读回密码——值只在当前运行期间存在
ephemeral "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret_version.ephemeral_demo.secret_id
}

# ══════════════════════════════════════════

locals {
  connection_string = "postgres://admin:${var.db_password}@db.${var.region}.example.com"
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
