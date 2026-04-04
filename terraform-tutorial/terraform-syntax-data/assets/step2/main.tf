# ══════════════════════════════════════════
# main.tf — 用数据源查询 setup.tf 创建的资源
# ══════════════════════════════════════════

# ── 数据源：查询已有的 S3 桶 ──
data "aws_s3_bucket" "config" {
  bucket = aws_s3_bucket.shared_config.id
}

# ── 数据源：查询已有的 SQS 队列 ──
data "aws_sqs_queue" "events" {
  name = aws_sqs_queue.shared_events.name
}

# ── 资源：使用数据源信息创建新资源 ──

# 创建一个应用日志桶
resource "aws_s3_bucket" "app_logs" {
  bucket = "app-logs-bucket"
}

# 在日志桶中记录数据来源信息
resource "aws_s3_object" "log_config" {
  bucket  = aws_s3_bucket.app_logs.id
  key     = "source-info.json"
  content = jsonencode({
    config_bucket_arn  = data.aws_s3_bucket.config.arn
    config_bucket_name = data.aws_s3_bucket.config.id
    events_queue_arn   = data.aws_sqs_queue.events.arn
    events_queue_url   = data.aws_sqs_queue.events.url
  })
  content_type = "application/json"
}

# 创建一个死信队列
resource "aws_sqs_queue" "dead_letter" {
  name = "events-dead-letter"
}

# 创建处理器队列，引用 data 查询到的事件队列信息
resource "aws_sqs_queue" "app_processor" {
  name = "app-event-processor"

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter.arn
    maxReceiveCount     = 3
  })

  tags = {
    SourceQueue = data.aws_sqs_queue.events.name
  }
}

# ── 输出 ──

output "config_bucket_arn" {
  value       = data.aws_s3_bucket.config.arn
  description = "通过 data 查询到的配置桶 ARN"
}

output "config_bucket_region" {
  value       = data.aws_s3_bucket.config.region
  description = "通过 data 查询到的配置桶所在区域"
}

output "events_queue_arn" {
  value       = data.aws_sqs_queue.events.arn
  description = "通过 data 查询到的事件队列 ARN"
}

output "events_queue_url" {
  value       = data.aws_sqs_queue.events.url
  description = "通过 data 查询到的事件队列 URL"
}

output "app_processor_queue_url" {
  value       = aws_sqs_queue.app_processor.url
  description = "新创建的处理器队列 URL"
}
