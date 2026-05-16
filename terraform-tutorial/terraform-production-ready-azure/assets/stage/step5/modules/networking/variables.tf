variable "app_name" { type = string }
variable "environment" { type = string }
variable "suffix" { type = string }
variable "location" { type = string }
variable "vnet_cidr" {
  type = string
  validation {
    condition     = can(cidrhost(var.vnet_cidr, 0))
    error_message = "vnet_cidr 必须是合法的 CIDR，例如 10.0.0.0/16。"
  }
}
