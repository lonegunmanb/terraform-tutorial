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
