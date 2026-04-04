terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = "test"
  secret_key = "test"

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    s3  = "http://localhost:4566"
    sqs = "http://localhost:4566"
  }
}

# ══════════════════════════════════════════
# 演示：check 块的基本用法
# ══════════════════════════════════════════

# ── 资源定义 ──

resource "aws_s3_bucket" "website" {
  bucket = "demo-website-bucket"
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.website.id
  key          = "index.html"
  content      = "<h1>Hello from Terraform check demo!</h1>"
  content_type = "text/html"
}

resource "aws_sqs_queue" "notifications" {
  name                       = "demo-notifications"
  visibility_timeout_seconds = 30
}

# ── check 块 1：验证 S3 桶的标签包含 ManagedBy ──
# 这个检查会产生警告，因为我们没有给桶设置标签
check "bucket_has_tags" {
  assert {
    condition     = length(aws_s3_bucket.website.tags_all) > 0
    error_message = "S3 桶 ${aws_s3_bucket.website.id} 没有设置任何标签，建议添加 ManagedBy 标签。"
  }
}

# ── check 块 2：验证 SQS 队列的可见性超时是否合理 ──
check "queue_timeout_reasonable" {
  assert {
    condition     = aws_sqs_queue.notifications.visibility_timeout_seconds >= 30
    error_message = "SQS 队列可见性超时低于 30 秒，可能导致消息重复消费。"
  }

  assert {
    condition     = aws_sqs_queue.notifications.visibility_timeout_seconds <= 300
    error_message = "SQS 队列可见性超时超过 300 秒，可能导致消息处理延迟过大。"
  }
}

# ── check 块 3：使用有限作用域数据源验证网站健康状态 ──
# 注意：LocalStack 不支持 S3 网站托管的 HTTP 访问，
# 所以这个检查会产生警告（数据源错误降级为警告）
check "website_health" {
  data "http" "website" {
    url = "http://localhost:4566/demo-website-bucket/index.html"

    depends_on = [aws_s3_object.index]
  }

  assert {
    condition     = data.http.website.status_code == 200
    error_message = "网站返回了非 200 状态码：${data.http.website.status_code}"
  }
}

# ── 输出 ──

output "bucket_name" {
  value = aws_s3_bucket.website.id
}

output "queue_url" {
  value = aws_sqs_queue.notifications.url
}
