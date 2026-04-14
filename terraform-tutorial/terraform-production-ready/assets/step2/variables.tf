variable "environment" {
  description = "部署环境（dev / stage / prod）"
  type        = string
  default     = "dev"
}

variable "app_name" {
  description = "应用名称，用作所有资源名称的前缀"
  type        = string
  default     = "config-center"
}
