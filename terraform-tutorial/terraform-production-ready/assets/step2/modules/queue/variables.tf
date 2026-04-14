variable "queue_name" {
  description = "SQS 队列名称"
  type        = string
}

variable "message_retention_seconds" {
  description = "消息保留时长（秒）"
  type        = number
  default     = 86400
}

variable "visibility_timeout_seconds" {
  description = "消息可见性超时（秒）"
  type        = number
  default     = 30
}
