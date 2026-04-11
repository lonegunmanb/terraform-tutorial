variable "environment" {
  type        = string
  default     = "dev"
  description = "部署环境"
}

variable "app_name" {
  type        = string
  default     = "myapp"
  description = "应用名称"
}
