# modules/storage/main.tf（step3：使用 terraform-aws-modules/s3-bucket）
#
# 用社区模块替换自制的 aws_s3_bucket + aws_s3_bucket_versioning。
# 外部接口（variables.tf / outputs.tf 中的变量和输出名）保持不变，
# 调用方（根模块的 main.tf）无需修改任何一行代码。

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.2"

  bucket = var.bucket_name

  versioning = {
    enabled = var.enable_versioning
  }
}
