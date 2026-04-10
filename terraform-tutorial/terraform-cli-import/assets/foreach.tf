# 用于 Step 3：for_each 导入
variable "bucket_envs" {
  type    = set(string)
  default = ["dev", "staging"]
}

resource "aws_s3_bucket" "per_env" {
  for_each = var.bucket_envs
  bucket   = "app-${each.key}"
  tags = {
    Environment = each.key
    ManagedBy   = "Terraform"
  }
}
