resource "aws_s3_bucket" "primary" {
  bucket = "${var.prefix}-primary"
}

resource "aws_s3_bucket" "replica" {
  bucket = "${var.prefix}-replica"
}
