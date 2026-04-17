# 存储层：静态资源 + 数据备份
# 对应三层架构中的 CDN/静态资源层（生产环境搭配 CloudFront）

resource "aws_s3_bucket" "static" {
  bucket = "${var.app_name}-${var.environment}-static"
}

resource "aws_s3_bucket_versioning" "static" {
  bucket = aws_s3_bucket.static.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket" "backups" {
  bucket = "${var.app_name}-${var.environment}-backups"
}

resource "aws_s3_bucket_versioning" "backups" {
  bucket = aws_s3_bucket.backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id
  rule {
    id     = "expire-old-backups"
    status = "Enabled"
    expiration {
      days = var.backup_expiration_days
    }
  }
}
