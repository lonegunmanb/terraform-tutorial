# ==============================
# Terraform 输入变量：赋值方式演示
# ==============================

# ── 有默认值的变量 ──
variable "app_name" {
  type        = string
  default     = "default-app"
  description = "应用名称（可通过 -var、.tfvars、环境变量等方式赋值）"
}

variable "replica_count" {
  type        = number
  default     = 1
  description = "副本数量"
}

variable "region" {
  type        = string
  default     = "us-east-1"
  description = "部署区域"
}

# ── 无默认值的变量（用于演示交互式输入）──
variable "project_id" {
  type        = string
  description = "项目 ID（无默认值，必须赋值，否则提示输入）"
}

locals {
  deployment_label = "${var.app_name}-${var.region}-x${var.replica_count}"
  full_id          = "${var.project_id}-${var.app_name}"
}

output "app_name" {
  value = var.app_name
}

output "replica_count" {
  value = var.replica_count
}

output "region" {
  value = var.region
}

output "project_id" {
  value = var.project_id
}

output "deployment_label" {
  value = local.deployment_label
}

output "full_id" {
  value = local.full_id
}
