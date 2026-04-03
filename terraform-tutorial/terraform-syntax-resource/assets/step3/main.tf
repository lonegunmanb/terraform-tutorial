terraform {
  required_version = ">= 1.0"
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
    s3       = "http://localhost:4566"
    sqs      = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
    sns      = "http://localhost:4566"
    sts      = "http://localhost:4566"
  }
}

# ══════════════════════════════════════════
# 场景：事件驱动的通知系统
# ══════════════════════════════════════════

# ── lifecycle 示例 ──

# 1. prevent_destroy：保护重要数据表不被意外删除
resource "aws_dynamodb_table" "audit_log" {
  name         = "audit-log"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "event_id"
  range_key    = "timestamp"

  attribute {
    name = "event_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  lifecycle {
    prevent_destroy = false  # 设为 true 可阻止 destroy，但因不支持变量配置，实际项目中较少使用
  }
}

# 2. ignore_changes：桶创建后由外部系统管理标签
resource "aws_s3_bucket" "uploads" {
  bucket = "user-uploads-bucket"

  tags = {
    ManagedBy = "terraform"
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

# 3. create_before_destroy：替换资源时保持可用性
resource "aws_sqs_queue" "processing" {
  name                       = "event-processing"
  visibility_timeout_seconds = 60

  lifecycle {
    create_before_destroy = true
  }
}

# ── dynamic 块示例 ──

# 使用 dynamic 块为 DynamoDB 表动态生成多个属性定义
variable "extra_attributes" {
  type = list(object({
    name = string
    type = string   # S = String, N = Number, B = Binary
  }))
  default = [
    { name = "user_id",    type = "S" },
    { name = "event_type", type = "S" },
    { name = "score",      type = "N" },
  ]
}

resource "aws_dynamodb_table" "events" {
  name         = "events-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user_id"
  range_key    = "event_type"

  # 使用 dynamic 块根据变量动态生成 attribute 块
  dynamic "attribute" {
    for_each = var.extra_attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  global_secondary_index {
    name            = "score-index"
    hash_key        = "event_type"
    range_key       = "score"
    projection_type = "ALL"
  }
}

output "events_table_arn" {
  value = aws_dynamodb_table.events.arn
}

# ── SNS + SQS 扇出：展示 dynamic 的实际应用 ──

resource "aws_sns_topic" "alerts" {
  name = "system-alerts"
}

variable "alert_subscribers" {
  type = map(string)
  default = {
    email_queue = "email-alert-queue"
    slack_queue = "slack-alert-queue"
    log_queue   = "log-alert-queue"
  }
}

# 使用 for_each 创建多个订阅队列
resource "aws_sqs_queue" "alert_sub" {
  for_each = var.alert_subscribers
  name     = each.value
}

# 使用 for_each 为每个队列创建 SNS 订阅
resource "aws_sns_topic_subscription" "queue_sub" {
  for_each = aws_sqs_queue.alert_sub

  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "sqs"
  endpoint  = each.value.arn
}

output "topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "subscriber_queues" {
  value = { for k, v in aws_sqs_queue.alert_sub : k => v.url }
}

# ── provisioner 示例 ──

# 使用 local-exec provisioner 在创建后记录信息
resource "aws_s3_bucket" "report" {
  bucket = "deployment-report"

  provisioner "local-exec" {
    command = "echo 'Bucket ${self.id} created at '$(date) >> /root/workspace/step3/deploy.log"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Bucket destroyed at '$(date) >> /root/workspace/step3/deploy.log"
  }
}

output "report_bucket_id" {
  value = aws_s3_bucket.report.id
}
