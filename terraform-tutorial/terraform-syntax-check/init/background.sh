#!/bin/bash
exec > /tmp/background.log 2>&1
set -x

source /root/setup-common.sh

mkdir -p /root/workspace/step1
mkdir -p /root/workspace/step2

# ── 1. Seed step1/main.tf ──
if [ ! -f /root/workspace/step1/main.tf ]; then
cat > /root/workspace/step1/main.tf << 'MAIN1EOF'
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
MAIN1EOF
fi

# ── 2. Seed step2/main.tf ──
if [ ! -f /root/workspace/step2/main.tf ]; then
cat > /root/workspace/step2/main.tf << 'MAIN2EOF'
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
MAIN2EOF
fi

# ── 3. Seed step2/check_test.tftest.hcl ──
if [ ! -f /root/workspace/step2/check_test.tftest.hcl ]; then
cat > /root/workspace/step2/check_test.tftest.hcl << 'TESTEOF'
# 测试 check 块是否正确定义

run "test_bucket_managed_tag_check" {
  assert {
    condition     = output.bucket_tags["ManagedBy"] == "terraform"
    error_message = "第 1 题：S3 桶的 ManagedBy 标签值不正确。"
  }
}

run "test_queue_retention_check" {
  assert {
    condition     = output.queue_retention >= 86400
    error_message = "第 2 题：SQS 队列的消息保留时间不足 1 天。"
  }
}

run "test_bucket_has_config_check" {
  assert {
    condition     = output.bucket_id == "quiz-data-bucket"
    error_message = "第 3 题：S3 桶 ID 不正确。"
  }
}
TESTEOF
fi

# ── 4. Seed docker-compose.yml ──
if [ ! -f /root/workspace/docker-compose.yml ]; then
cat > /root/workspace/docker-compose.yml << 'DCEOF'
services:
  localstack:
    image: localstack/localstack:3
    ports:
      - "4566:4566"
    environment:
      - SERVICES=s3,sqs
      - DEFAULT_REGION=us-east-1
      - EAGER_SERVICE_LOADING=1
    deploy:
      resources:
        limits:
          memory: 1536M
DCEOF
fi

# ── 5. Install tools ──
install_terraform
install_awscli

# ── 6. Start LocalStack ──
start_localstack

# ── 7. Pre-init step1 to speed up student experience ──
cd /root/workspace/step1
terraform init

# ── 8. Signal completion ──
finish_setup
