variable "environment" {
  type        = string
  default     = "dev"
  description = "部署环境"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment 必须是 dev、staging 或 prod 之一"
  }
}

variable "app_name" {
  type        = string
  default     = "myapp"
  description = "应用名称"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,20}$", var.app_name))
    error_message = "app_name 必须以小写字母开头，只含小写字母、数字和连字符，长度 2-21"
  }
}

variable "suffix" {
  type        = string
  default     = "lab"
  description = "资源名称后缀"
}
