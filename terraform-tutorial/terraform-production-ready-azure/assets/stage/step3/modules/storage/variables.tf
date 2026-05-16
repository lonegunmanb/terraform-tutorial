variable "app_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "suffix" {
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
