variable "app_name" { type = string }
variable "environment" { type = string }
variable "suffix" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "web_subnet_id" { type = string }
variable "web_nsg_id" { type = string }
variable "vm_size" {
  type    = string
  default = "Standard_B1s"
}
