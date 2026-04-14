variable "bucket_name" {
  description = "S3 存储桶名称"
  type        = string
}

variable "enable_versioning" {
  description = "是否开启版本控制"
  type        = bool
  default     = true
}
