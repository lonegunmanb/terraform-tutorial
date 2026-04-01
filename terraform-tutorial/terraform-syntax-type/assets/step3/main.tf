# ==============================
# Terraform 类型示例：结构化类型
# ==============================

# ── object 类型 ──
# object 由一组命名属性组成，每个属性可以有不同的类型
variable "server" {
  type = object({
    name   = string
    port   = number
    active = bool
  })
  default = {
    name   = "web-01"
    port   = 8080
    active = true
  }
}

# ── tuple 类型 ──
# tuple 类似 list，但每个位置可以有不同的类型
variable "record" {
  type    = tuple([string, number, bool])
  default = ["hello", 42, true]
}

# ── object 的 optional 成员（Terraform >= 1.3）──
variable "database" {
  type = object({
    engine  = string
    version = optional(string, "14")
    port    = optional(number, 5432)
    config  = optional(object({
      max_connections = optional(number, 100)
      ssl_enabled     = optional(bool, true)
    }), {})
  })
  default = {
    engine = "postgresql"
  }
}

# ── any 类型约束 ──
variable "flexible" {
  type    = any
  default = "anything goes"
}

# ── null 值 ──
variable "maybe_name" {
  type    = string
  default = null
}

locals {
  # 访问 object 属性
  server_name = var.server.name
  server_port = var.server.port

  # 访问 tuple 元素（下标访问）
  record_name = var.record[0]
  record_num  = var.record[1]

  # optional 属性的默认值生效
  db_version = var.database.version
  db_port    = var.database.port
  db_max_conn = var.database.config.max_connections
  db_ssl      = var.database.config.ssl_enabled

  # null 与默认值
  display_name = var.maybe_name != null ? var.maybe_name : "anonymous"
}

output "server_name" {
  value = local.server_name
}

output "server_port" {
  value = local.server_port
}

output "record_name" {
  value = local.record_name
}

output "record_num" {
  value = local.record_num
}

output "db_version" {
  value = local.db_version
}

output "db_port" {
  value = local.db_port
}

output "db_max_conn" {
  value = local.db_max_conn
}

output "db_ssl" {
  value = local.db_ssl
}

output "display_name" {
  value = local.display_name
}
