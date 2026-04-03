#!/bin/bash
exec > /tmp/background.log 2>&1
set -x

source /root/setup-common.sh

# ── 1. Ensure workspace directories exist ──
mkdir -p /root/workspace/step1
mkdir -p /root/workspace/step2
mkdir -p /root/workspace/step3

# ── 2. Seed workspace files (fallback if assets copy fails) ──

if [ ! -f /root/workspace/step1/main.tf ]; then
cat > /root/workspace/step1/main.tf <<'EOTF'
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
    s3  = "http://localhost:4566"
    sqs = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}

# ── 场景：静态网站托管 ──

# 1. 创建 S3 存储桶
resource "aws_s3_bucket" "website" {
  bucket = "my-tutorial-website"
}

# 2. 上传首页文件
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.website.id
  key          = "index.html"
  content      = <<-HTML
    <!DOCTYPE html>
    <html>
    <head><title>Terraform Tutorial</title></head>
    <body>
      <h1>Hello from Terraform!</h1>
      <p>This page was deployed by Terraform to S3.</p>
    </body>
    </html>
  HTML
  content_type = "text/html"
}

# 3. 上传错误页面
resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.website.id
  key          = "error.html"
  content      = <<-HTML
    <!DOCTYPE html>
    <html>
    <head><title>404 Not Found</title></head>
    <body><h1>Oops! Page not found.</h1></body>
    </html>
  HTML
  content_type = "text/html"
}

# 4. 创建通知队列（演示隐式依赖）
resource "aws_sqs_queue" "notifications" {
  name                       = "website-notifications"
  delay_seconds              = 0
  max_message_size           = 262144
  message_retention_seconds  = 86400
  visibility_timeout_seconds = 30
}

# ── 输出：引用资源属性 ──

output "bucket_id" {
  value       = aws_s3_bucket.website.id
  description = "S3 桶的 ID"
}

output "bucket_arn" {
  value       = aws_s3_bucket.website.arn
  description = "S3 桶的 ARN"
}

output "index_page_etag" {
  value       = aws_s3_object.index.etag
  description = "首页文件的 ETag（内容哈希）"
}

output "queue_url" {
  value       = aws_sqs_queue.notifications.url
  description = "SQS 队列的 URL"
}

output "queue_arn" {
  value       = aws_sqs_queue.notifications.arn
  description = "SQS 队列的 ARN"
}
EOTF
fi

if [ ! -f /root/workspace/step2/main.tf ]; then
cat > /root/workspace/step2/main.tf <<'EOTF'
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
    sts      = "http://localhost:4566"
  }
}

# ══════════════════════════════════════════
# 场景：微服务消息系统
# ══════════════════════════════════════════

# ── count 示例：创建多个 SQS 队列 ──

variable "queue_count" {
  type    = number
  default = 3
}

resource "aws_sqs_queue" "worker" {
  count = var.queue_count
  name  = "worker-queue-${count.index}"

  visibility_timeout_seconds = 30
  message_retention_seconds  = 86400
}

output "worker_queue_urls" {
  value       = aws_sqs_queue.worker[*].url
  description = "所有 worker 队列的 URL（使用 splat）"
}

output "first_queue_arn" {
  value       = aws_sqs_queue.worker[0].arn
  description = "第一个 worker 队列的 ARN（下标访问）"
}

# ── for_each + map 示例：为不同服务创建 DynamoDB 表 ──

variable "tables" {
  type = map(object({
    hash_key  = string
    range_key = string
  }))
  default = {
    users = {
      hash_key  = "user_id"
      range_key = "email"
    }
    orders = {
      hash_key  = "order_id"
      range_key = "created_at"
    }
    products = {
      hash_key  = "product_id"
      range_key = "category"
    }
  }
}

resource "aws_dynamodb_table" "service" {
  for_each = var.tables

  name         = "${each.key}-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = each.value.hash_key
  range_key    = each.value.range_key

  attribute {
    name = each.value.hash_key
    type = "S"
  }

  attribute {
    name = each.value.range_key
    type = "S"
  }
}

output "table_arns" {
  value       = { for k, v in aws_dynamodb_table.service : k => v.arn }
  description = "所有 DynamoDB 表的 ARN"
}

# ── for_each + set 示例：创建多个 S3 数据桶 ──

variable "bucket_names" {
  type    = list(string)
  default = ["raw-data", "processed-data", "archive-data"]
}

resource "aws_s3_bucket" "data" {
  for_each = toset(var.bucket_names)
  bucket   = "myapp-${each.key}"
}

output "data_bucket_ids" {
  value       = { for k, v in aws_s3_bucket.data : k => v.id }
  description = "所有数据桶的 ID"
}

# ── depends_on 示例：隐式 vs 显式依赖 ──

# --- 隐式依赖（不需要 depends_on）---
# main_queue 的 redrive_policy 引用了 dead_letter.arn，
# Terraform 自动推导出 dead_letter 必须先创建。

resource "aws_sqs_queue" "dead_letter" {
  name = "dead-letter-queue"
}

resource "aws_sqs_queue" "main_queue" {
  name = "main-processing-queue"

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter.arn
    maxReceiveCount     = 3
  })
  # 注意：这里不需要 depends_on，因为上面的 .arn 引用已经
  # 让 Terraform 知道了依赖关系。
}

# --- 显式依赖（必须用 depends_on）---
# setup_step 执行一个初始化脚本，app_queue 运行时需要这个
# 初始化步骤已完成，但代码中没有引用 setup_step 的任何属性，
# Terraform 无法自动推导出依赖关系——必须用 depends_on。

resource "terraform_data" "setup_step" {
  provisioner "local-exec" {
    command = "echo '{\"initialized\": true}' > /tmp/app-config.json"
  }
}

resource "aws_sqs_queue" "app_queue" {
  name = "app-queue"

  # 代码中没有引用 setup_step 的属性，但运行时需要它先完成。
  # 没有这行，Terraform 可能并行创建两者，导致初始化未完成。
  depends_on = [terraform_data.setup_step]
}

output "main_queue_url" {
  value = aws_sqs_queue.main_queue.url
}

output "app_queue_url" {
  value = aws_sqs_queue.app_queue.url
}

# ══════════════════════════════════════════
# count vs for_each 对比实验
# 同一个列表，分别用 count 和 for_each 创建资源
# 删除中间元素后观察两者的差异
# ══════════════════════════════════════════

variable "subnet_ids" {
  type    = list(string)
  default = ["subnet-aaa", "subnet-bbb", "subnet-ccc"]
}

# 用 count 创建：按数字索引绑定
resource "aws_sqs_queue" "count_demo" {
  count = length(var.subnet_ids)
  name  = "count-${var.subnet_ids[count.index]}"
}

# 用 for_each 创建：按键绑定
resource "aws_sqs_queue" "foreach_demo" {
  for_each = toset(var.subnet_ids)
  name     = "foreach-${each.key}"
}

output "count_demo_names" {
  value = aws_sqs_queue.count_demo[*].name
}

output "foreach_demo_names" {
  value = { for k, v in aws_sqs_queue.foreach_demo : k => v.name }
}
EOTF
fi

if [ ! -f /root/workspace/step3/main.tf ]; then
cat > /root/workspace/step3/main.tf <<'EOTF'
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
    prevent_destroy = false  # 实验中设为 false 方便清理；生产环境应设为 true
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
EOTF
fi

if [ ! -f /root/workspace/docker-compose.yml ]; then
cat > /root/workspace/docker-compose.yml <<'EODC'
services:
  localstack:
    image: localstack/localstack:3
    ports:
      - "4566:4566"
    environment:
      - SERVICES=s3,sqs,dynamodb,sns
      - DEFAULT_REGION=us-east-1
      - EAGER_SERVICE_LOADING=1
    deploy:
      resources:
        limits:
          memory: 1536M
EODC
fi

# ── 3. Install tools ──
install_terraform

# ── 4. Start LocalStack ──
start_localstack

# ── 5. Pre-init step1 to speed up student experience ──
cd /root/workspace/step1
terraform init

# ── 6. Signal completion ──
finish_setup
