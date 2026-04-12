variable "bucket_name" {
  type        = string
  description = "The name of the S3 bucket for static website hosting. Must be globally unique."
}

variable "force_destroy" {
  type        = bool
  default     = false
  description = "Whether to force destroy the bucket and all its contents when the resource is deleted."
}

variable "index_document" {
  type        = string
  default     = "index.html"
  description = "The name of the index document for the website."
}

variable "error_document" {
  type        = string
  default     = "error.html"
  description = "The name of the error document for the website."
}

variable "enable_versioning" {
  type        = bool
  default     = false
  description = "Whether to enable versioning on the S3 bucket."
}

variable "allow_public_access" {
  type        = bool
  default     = false
  description = "Whether to allow public access to the S3 bucket. Set to true for public static websites."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "A map of tags to assign to all resources created by this module."
}
