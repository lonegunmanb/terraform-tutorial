variable "bucket_name" {
  type        = string
  description = "S3 桶的名称"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "附加到桶上的标签"
}
