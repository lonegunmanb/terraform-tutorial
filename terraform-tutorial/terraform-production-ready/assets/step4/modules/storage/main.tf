# modules/storage/main.tf（step4：在 step3 基础上加入 precondition）

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.2"

  bucket = var.bucket_name

  versioning = {
    enabled = var.enable_versioning
  }
}

# precondition 在 apply 之前"提前断言"——如果传入的名称不符合 AWS S3 规范，
# 立即报错，而不是等到 API 调用失败后再抛出一个难以阅读的错误信息。
resource "null_resource" "bucket_name_guard" {
  lifecycle {
    precondition {
      condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
      error_message = "S3 存储桶名称长度必须在 3 到 63 个字符之间（AWS 规范）。当前值：\"${var.bucket_name}\"（${length(var.bucket_name)} 个字符）"
    }
  }
}
