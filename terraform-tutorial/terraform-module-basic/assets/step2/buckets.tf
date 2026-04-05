# 数据桶
resource "aws_s3_bucket" "data" {
  bucket = "${var.project}-data"
}
