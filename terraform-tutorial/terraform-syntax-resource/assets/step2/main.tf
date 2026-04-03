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
