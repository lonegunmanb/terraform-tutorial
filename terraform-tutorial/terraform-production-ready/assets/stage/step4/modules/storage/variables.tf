variable "app_name" {
  type = string
  validation {
    condition     = length(var.app_name) >= 3
    error_message = "app_name 至少需要 3 个字符，当前值为 '${var.app_name}'。"
  }
}

variable "environment" {
  type = string
}

variable "enable_versioning" {
  type    = bool
  default = true
}

variable "backup_expiration_days" {
  type    = number
  default = 90
}
