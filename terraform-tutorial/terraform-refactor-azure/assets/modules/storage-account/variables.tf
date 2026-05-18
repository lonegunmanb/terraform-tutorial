variable "name" {
  type        = string
  description = "Storage Account 名称（3-24 字符，仅小写字母与数字）"
}

variable "resource_group_name" {
  type        = string
  description = "所属 Resource Group 名称"
}

variable "location" {
  type        = string
  default     = "eastus"
  description = "Azure 区域"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "附加到 Storage Account 的标签"
}
