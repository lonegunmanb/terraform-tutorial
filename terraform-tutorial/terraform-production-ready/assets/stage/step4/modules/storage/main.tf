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

resource "terraform_data" "bucket_name_check" {
  lifecycle {
    precondition {
      condition     = length(var.app_name) >= 3 && length("${var.app_name}-${var.environment}-backups") <= 63
      error_message = "S3 桶名必须在 3–63 字符之间。app_name 至少 3 个字符，且 app_name + environment + 后缀的总长度不能超过 63。当前 app_name='${var.app_name}', environment='${var.environment}'。"
    }
  }
}
