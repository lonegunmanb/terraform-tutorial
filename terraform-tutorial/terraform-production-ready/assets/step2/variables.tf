variable "environment" {
  type    = string
  default = "dev"
}

variable "app_name" {
  type    = string
  default = "webapp"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
