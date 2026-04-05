# 日志桶 —— 和 buckets.tf 中的资源属于同一个模块
resource "aws_s3_bucket" "logs" {
  bucket = "${var.project}-logs"
}
