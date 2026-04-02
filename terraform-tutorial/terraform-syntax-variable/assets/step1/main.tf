# ==============================
# Terraform 输入变量：基础用法
# ==============================

# ── string 类型变量 ──
variable "project" {
  type        = string
  default     = "my-app"
  description = "项目名称"
}

# ── number 类型变量 ──
variable "port" {
  type        = number
  default     = 8080
  description = "应用端口号"
}

# ── bool 类型变量 ──
variable "enabled" {
  type        = bool
  default     = true
  description = "是否启用服务"
}

# ── 复合类型变量 ──
variable "tags" {
  type = map(string)
  default = {
    Environment = "dev"
    Team        = "platform"
  }
  description = "资源标签"
}

# ── 有默认值的变量 ──
variable "owner" {
  type        = string
  default     = "terraform-user"
  description = "资源所有者（有默认值，不会提示输入）"
}

# ── nullable = false：不允许为 null ──
variable "region" {
  type        = string
  default     = "us-east-1"
  nullable    = false
  description = "部署区域，不允许为 null"
}

# ── 通过 var.<NAME> 引用变量 ──
locals {
  greeting    = "Project: ${var.project}"
  port_string = "Port is ${var.port}"
  status      = var.enabled ? "enabled" : "disabled"
  full_label  = "${var.project}-${var.tags["Environment"]}"
}

output "project" {
  value = var.project
}

output "port" {
  value = var.port
}

output "enabled" {
  value = var.enabled
}

output "tags" {
  value = var.tags
}

output "owner" {
  value = var.owner
}

output "region" {
  value = var.region
}

output "greeting" {
  value = local.greeting
}

output "port_string" {
  value = local.port_string
}

output "status" {
  value = local.status
}

output "full_label" {
  value = local.full_label
}
