variable "app_name" {
  type = string
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
