#!/bin/bash
exec > /tmp/background.log 2>&1
set -x

source /root/setup-common.sh

# ── 1. Ensure workspace directories exist ──
mkdir -p /root/workspace/step1
mkdir -p /root/workspace/step2
mkdir -p /root/workspace/step3/tests

# ── 2. Seed workspace files (fallback if assets copy fails) ──

if [ ! -f /root/workspace/step1/main.tf ]; then
cat > /root/workspace/step1/main.tf <<'EOTF'
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
EOTF
fi

if [ ! -f /root/workspace/step2/main.tf ]; then
cat > /root/workspace/step2/main.tf <<'EOTF'
# ==============================
# Terraform 输出值示例：sensitive 与 precondition
# ==============================

# ── sensitive 输出 ──

variable "db_password" {
  type      = string
  default   = "super-secret-password-123"
  sensitive = true
}

variable "api_key" {
  type    = string
  default = "sk-abcdef1234567890"
}

# 标记为 sensitive 的输出——apply 后显示 <sensitive>
output "database_password" {
  value     = var.db_password
  sensitive = true
}

# 引用 sensitive 变量的输出也必须标记为 sensitive
output "connection_string" {
  value     = "postgresql://admin:${var.db_password}@localhost:5432/mydb"
  sensitive = true
}

# 普通输出（非 sensitive）——apply 后正常显示
output "api_endpoint" {
  value = "https://api.example.com/v1"
}

# ── precondition 输出 ──

variable "instance_count" {
  type    = number
  default = 3
}

variable "server_name" {
  type    = string
  default = "web-server"
}

locals {
  servers = [for i in range(var.instance_count) : {
    name = "${var.server_name}-${i}"
    ip   = "10.0.1.${i + 10}"
    port = 8080 + i
  }]
}

# 带 precondition 的输出——在计算 value 之前校验条件
output "primary_server" {
  value = local.servers[0].ip

  precondition {
    condition     = var.instance_count > 0
    error_message = "至少需要 1 个实例才能输出 primary_server。"
  }
}

output "server_list" {
  value       = local.servers
  description = "List of all server instances with name, IP, and port."

  precondition {
    condition     = var.instance_count <= 10
    error_message = "实例数量不能超过 10 个。"
  }
}

# ── 综合示例：sensitive + description ──
output "admin_credentials" {
  value = {
    username = "admin"
    password = var.db_password
    api_key  = var.api_key
  }
  description = "Admin credentials for the application. Handle with care."
  sensitive   = true
}
EOTF
fi

# ── 3. Call setup functions ──
install_terraform
finish_setup
