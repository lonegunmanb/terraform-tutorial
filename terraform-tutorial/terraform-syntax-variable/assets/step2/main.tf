# ==============================
# Terraform 输入变量：断言校验
# ==============================

# ── 简单条件校验 ──
variable "instance_count" {
  type        = number
  default     = 3
  description = "实例数量，必须在 1-10 之间"

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "instance_count 必须在 1 到 10 之间。"
  }
}

# ── 使用 can + regex 校验格式 ──
variable "image_id" {
  type        = string
  default     = "ami-abc12345"
  description = "机器镜像 ID，必须以 ami- 开头"

  validation {
    condition     = can(regex("^ami-", var.image_id))
    error_message = "image_id 必须以 \"ami-\" 开头。"
  }
}

# ── 使用 contains 校验枚举值 ──
variable "environment" {
  type        = string
  default     = "dev"
  description = "部署环境，仅允许 dev、staging、prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment 必须是 dev、staging 或 prod 之一。"
  }
}

# ── 多重校验（一个变量多个 validation 块）──
variable "bucket_name" {
  type        = string
  default     = "my-demo-bucket"
  description = "S3 存储桶名称"

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "bucket_name 长度必须在 3-63 个字符之间。"
  }

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.bucket_name))
    error_message = "bucket_name 只能包含小写字母、数字、点和连字符，且必须以字母或数字开头和结尾。"
  }
}

# ── 跨变量引用校验（Terraform >= 1.9）──
variable "min_count" {
  type        = number
  default     = 1
  description = "最小实例数"
}

variable "max_count" {
  type        = number
  default     = 10
  description = "最大实例数，必须 >= min_count"

  validation {
    condition     = var.max_count >= var.min_count
    error_message = "max_count（${var.max_count}）不能小于 min_count（${var.min_count}）。"
  }
}

locals {
  summary     = "环境: ${var.environment}, 实例: ${var.instance_count}, 镜像: ${var.image_id}, 桶: ${var.bucket_name}"
  count_range = "${var.min_count} ~ ${var.max_count}"
}

output "instance_count" {
  value = var.instance_count
}

output "image_id" {
  value = var.image_id
}

output "environment" {
  value = var.environment
}

output "bucket_name" {
  value = var.bucket_name
}

output "min_count" {
  value = var.min_count
}

output "max_count" {
  value = var.max_count
}

output "count_range" {
  value = local.count_range
}

output "summary" {
  value = local.summary
}
