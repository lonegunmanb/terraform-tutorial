# ==============================
# Terraform 类型示例：原始类型
# ==============================

# ── string 类型 ──
variable "name" {
  type    = string
  default = "Terraform"
}

# ── number 类型 ──
variable "port" {
  type    = number
  default = 8080
}

variable "pi" {
  type    = number
  default = 3.14159
}

# ── bool 类型 ──
variable "enabled" {
  type    = bool
  default = true
}

# ── 隐式类型转换演示 ──
# number 和 bool 都可以与 string 互相隐式转换
variable "string_number" {
  type    = string
  default = "42"
}

variable "string_bool" {
  type    = string
  default = "true"
}

locals {
  # string → number 的隐式转换
  computed_number = var.string_number + 1
  # => 43（字符串 "42" 自动转换为数字 42）

  # string → bool 的隐式转换
  computed_bool = var.string_bool ? "yes" : "no"
  # => "yes"（字符串 "true" 自动转换为 true）

  # number → string 的隐式转换
  port_label = "Port: ${var.port}"
  # => "Port: 8080"（数字自动转换为字符串）
}

output "name" {
  value = var.name
}

output "port" {
  value = var.port
}

output "pi" {
  value = var.pi
}

output "enabled" {
  value = var.enabled
}

output "computed_number" {
  value = local.computed_number
}

output "computed_bool" {
  value = local.computed_bool
}

output "port_label" {
  value = local.port_label
}
