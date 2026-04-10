# 用于 Step 2：import 块声明式导入
resource "aws_s3_bucket" "logs" {
  bucket = "legacy-logs"
  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket" "archive" {
  bucket = "legacy-archive"
  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

import {
  to = aws_s3_bucket.logs
  id = "legacy-logs"
}

import {
  to = aws_s3_bucket.archive
  id = "legacy-archive"
}
