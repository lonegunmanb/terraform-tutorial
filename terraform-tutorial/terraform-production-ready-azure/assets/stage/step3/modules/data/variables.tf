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

variable "offer_type" {
  type    = string
  default = "Standard"
}
