variable "app_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "billing_mode" {
  type    = string
  default = "PAY_PER_REQUEST"
}

variable "message_retention_seconds" {
  type    = number
  default = 86400

  validation {
    condition     = var.message_retention_seconds >= 60 && var.message_retention_seconds <= 1209600
    error_message = "消息保留时长必须在 60（1 分钟）到 1209600（14 天）秒之间。"
  }
}
