variable "queue_name" {
  description = "SQS 队列名称"
  type        = string
}

variable "message_retention_seconds" {
  description = "消息保留时长（秒），SQS 允许 60–1209600（1 分钟到 14 天）"
  type        = number
  default     = 86400

  validation {
    condition     = var.message_retention_seconds >= 60 && var.message_retention_seconds <= 1209600
    error_message = "消息保留时长必须在 60 到 1209600 秒（1 分钟到 14 天）之间。"
  }
}

variable "visibility_timeout_seconds" {
  description = "消息可见性超时（秒），SQS 允许 0–43200（12 小时）"
  type        = number
  default     = 30

  validation {
    condition     = var.visibility_timeout_seconds >= 0 && var.visibility_timeout_seconds <= 43200
    error_message = "可见性超时必须在 0 到 43200 秒（12 小时）之间。"
  }
}
