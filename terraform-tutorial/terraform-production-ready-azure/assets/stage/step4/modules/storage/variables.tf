variable "app_name" {
  type = string
  validation {
    condition     = length(var.app_name) >= 3 && can(regex("^[a-z0-9]+$", var.app_name))
    error_message = "app_name 至少 3 个字符，且只能包含小写字母和数字，以满足 Storage Account 命名要求。"
  }
}
variable "environment" { type = string }
variable "suffix" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
