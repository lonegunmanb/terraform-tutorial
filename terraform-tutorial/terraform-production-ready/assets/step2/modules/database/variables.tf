variable "table_name" {
  description = "DynamoDB 表名称"
  type        = string
}

variable "hash_key" {
  description = "分区键属性名"
  type        = string
  default     = "id"
}

variable "range_key" {
  description = "排序键属性名"
  type        = string
  default     = "timestamp"
}
