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

# ── 数据源：查询环境信息 ──

# 查询当前 AWS 账号信息（在 LocalStack 中返回模拟值）
data "aws_caller_identity" "current" {}

# 查询当前区域
data "aws_region" "current" {}

# ── 资源：使用数据源的信息 ──

# 用账号 ID 和区域构建桶名，确保全局唯一
resource "aws_s3_bucket" "app_data" {
  bucket = "app-data-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
}

# 创建一个带元数据的对象，记录谁创建了它
resource "aws_s3_object" "metadata" {
  bucket  = aws_s3_bucket.app_data.id
  key     = "metadata.json"
  content = jsonencode({
    account_id = data.aws_caller_identity.current.account_id
    region     = data.aws_region.current.name
    arn        = data.aws_caller_identity.current.arn
    created_by = "terraform"
  })
  content_type = "application/json"
}

# ── 输出 ──

output "account_id" {
  value       = data.aws_caller_identity.current.account_id
  description = "当前 AWS 账号 ID"
}

output "caller_arn" {
  value       = data.aws_caller_identity.current.arn
  description = "当前调用者 ARN"
}

output "region" {
  value       = data.aws_region.current.name
  description = "当前区域"
}

output "bucket_name" {
  value       = aws_s3_bucket.app_data.id
  description = "桶名（包含账号 ID 和区域）"
}
EOTF
fi

if [ ! -f /root/workspace/step2/setup.tf ]; then
cat > /root/workspace/step2/setup.tf <<'EOTF'
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
# setup.tf — 先创建一些"已有"资源
# 模拟在 data 查询之前就存在的基础设施
# ══════════════════════════════════════════

resource "aws_s3_bucket" "shared_config" {
  bucket = "shared-config-bucket"
}

resource "aws_s3_object" "app_config" {
  bucket       = aws_s3_bucket.shared_config.id
  key          = "app/config.json"
  content      = jsonencode({
    db_host = "db.internal.example.com"
    db_port = 5432
    cache   = "redis.internal.example.com"
    log_level = "info"
  })
  content_type = "application/json"
}

resource "aws_sqs_queue" "shared_events" {
  name                       = "shared-events-queue"
  message_retention_seconds  = 345600
  visibility_timeout_seconds = 60
}
EOTF
fi

if [ ! -f /root/workspace/step2/main.tf ]; then
cat > /root/workspace/step2/main.tf <<'EOTF'
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

# 创建一个应用桶，通过 data 获取 shared_config 桶的 ARN
resource "aws_s3_bucket" "app_logs" {
  bucket = "app-logs-bucket"
}

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

# 创建一个死信队列，关联到已有的 events 队列
resource "aws_sqs_queue" "dead_letter" {
  name = "events-dead-letter"
}

resource "aws_sqs_queue" "app_processor" {
  name = "app-event-processor"

  # 通过 data 获取 events 队列的 ARN 构建通知链
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
    s3  = "http://localhost:4566"
    sqs = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}

# ══════════════════════════════════════════════
# 小测验：补全缺失的 data 块，让 terraform test 通过
# ══════════════════════════════════════════════

# ── 资源（已提供，不要修改）──

resource "aws_s3_bucket" "web" {
  bucket = "quiz-web-bucket"
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.web.id
  key          = "index.html"
  content      = "<h1>Hello</h1>"
  content_type = "text/html"
}

resource "aws_sqs_queue" "tasks" {
  name                       = "quiz-task-queue"
  visibility_timeout_seconds = 45
}

# ── 第 1 题 ──
# 添加一个 data 块查询当前 AWS 区域
# 类型：aws_region，名称：current
# 文档：https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region
#
# 在下方写你的代码：


# ── 第 2 题 ──
# 添加一个 data 块查询当前调用者身份
# 类型：aws_caller_identity，名称：current
# 文档：https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity
#
# 在下方写你的代码：


# ── 第 3 题 ──
# 添加一个 data 块，通过桶名反查上面创建的 aws_s3_bucket.web
# 类型：aws_s3_bucket，名称：web_lookup
# 提示：查询参数 bucket 应引用 aws_s3_bucket.web.id
# 文档：https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket
#
# 在下方写你的代码：


# ── 第 4 题 ──
# 添加一个 data 块，通过队列名反查上面创建的 aws_sqs_queue.tasks
# 类型：aws_sqs_queue，名称：tasks_lookup
# 提示：查询参数 name 应引用 aws_sqs_queue.tasks.name
# 文档：https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/sqs_queue
#
# 在下方写你的代码：


# ── 输出（已提供，不要修改）──
# 这些 output 引用了你需要补全的 data 块
# 如果 data 块缺失，terraform plan 会报错

output "region" {
  value = data.aws_region.current.name
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "web_bucket_arn_from_data" {
  value = data.aws_s3_bucket.web_lookup.arn
}

output "task_queue_arn_from_data" {
  value = data.aws_sqs_queue.tasks_lookup.arn
}

output "task_queue_url_from_data" {
  value = data.aws_sqs_queue.tasks_lookup.url
}
EOTF
fi

if [ ! -f /root/workspace/step3/data_test.tftest.hcl ]; then
cat > /root/workspace/step3/data_test.tftest.hcl <<'EOTF'
# ══════════════════════════════════════════════════════
# 小测验：补全 main.tf 中缺失的 data 块，让所有测试通过
# ══════════════════════════════════════════════════════
# 此文件不需要修改。请在 main.tf 中添加缺失的 data 块。

# ── 测试 1：区域查询 ──
# 验证 data "aws_region" "current" 返回的区域与 provider 配置一致
run "test_region" {
  command = apply

  assert {
    condition     = output.region == "us-east-1"
    error_message = "区域应为 us-east-1"
  }
}

# ── 测试 2：调用者身份查询 ──
# 验证 data "aws_caller_identity" "current" 返回的 account_id 非空
run "test_account_id_not_empty" {
  command = apply

  assert {
    condition     = length(output.account_id) > 0
    error_message = "account_id 不应为空"
  }
}

# ── 测试 3：S3 桶反查 ──
# 验证通过 data "aws_s3_bucket" 反查得到的 ARN 包含桶名
run "test_bucket_lookup_arn" {
  command = apply

  assert {
    condition     = strcontains(output.web_bucket_arn_from_data, "quiz-web-bucket")
    error_message = "通过 data 查询到的桶 ARN 应包含 quiz-web-bucket"
  }
}

# ── 测试 4：SQS 队列反查 ──
# 验证通过 data "aws_sqs_queue" 反查得到的 ARN 以 "arn:" 开头
run "test_queue_lookup_arn" {
  command = apply

  assert {
    condition     = startswith(output.task_queue_arn_from_data, "arn:")
    error_message = "通过 data 查询到的队列 ARN 应以 arn: 开头"
  }
}

# ── 测试 5：SQS 队列 URL 反查 ──
# 验证通过 data 查询到的队列 URL 包含队列名
run "test_queue_lookup_url" {
  command = apply

  assert {
    condition     = strcontains(output.task_queue_url_from_data, "quiz-task-queue")
    error_message = "通过 data 查询到的队列 URL 应包含 quiz-task-queue"
  }
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
      - SERVICES=s3,sqs,sts
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
install_awscli

# ── 4. Start LocalStack ──
start_localstack

# ── 5. Pre-init step1 to speed up student experience ──
cd /root/workspace/step1
terraform init

# ── 6. Signal completion ──
finish_setup
