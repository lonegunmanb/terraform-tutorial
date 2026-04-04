terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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
# 小测验：补全缺失的 check 块，让 terraform test 通过
# ══════════════════════════════════════════

# ── 资源（已提供，不要修改）──

resource "aws_s3_bucket" "data" {
  bucket = "quiz-data-bucket"
  tags = {
    ManagedBy   = "terraform"
    Environment = "dev"
  }
}

resource "aws_s3_object" "config" {
  bucket       = aws_s3_bucket.data.id
  key          = "config.json"
  content      = jsonencode({ version = "1.0", debug = false })
  content_type = "application/json"
}

resource "aws_sqs_queue" "orders" {
  name                       = "quiz-orders-queue"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 86400
}

# ── 第 1 题 ──
# 添加一个 check 块，验证 S3 桶设置了 ManagedBy 标签
# check 名称：bucket_managed_tag
# 断言条件：aws_s3_bucket.data.tags["ManagedBy"] 不为空字符串
# 错误信息："S3 桶缺少 ManagedBy 标签。"
#
# 在下方写你的代码：


# ── 第 2 题 ──
# 添加一个 check 块，验证 SQS 队列的消息保留时间至少为 1 天（86400 秒）
# check 名称：queue_retention
# 断言条件：aws_sqs_queue.orders.message_retention_seconds >= 86400
# 错误信息："SQS 队列的消息保留时间不足 1 天。"
#
# 在下方写你的代码：


# ── 第 3 题 ──
# 添加一个 check 块，包含一个有限作用域的数据源和断言
# check 名称：bucket_has_config
# 数据源类型：aws_s3_object，名称：config_lookup
# 数据源参数：bucket = aws_s3_bucket.data.id, key = "config.json"
# 断言条件：data.aws_s3_object.config_lookup.content_length > 0
# 错误信息："配置文件 config.json 内容为空。"
#
# 在下方写你的代码：


# ── 输出（已提供，不要修改）──

output "bucket_id" {
  value = aws_s3_bucket.data.id
}

output "bucket_tags" {
  value = aws_s3_bucket.data.tags
}

output "queue_retention" {
  value = aws_sqs_queue.orders.message_retention_seconds
}
