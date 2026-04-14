variable "app_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "billing_mode" {
  type    = string
  default = "PAY_PER_REQUEST"
}

variable "message_retention_seconds" {
  type    = number
  default = 86400
}
