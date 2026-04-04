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

# ══════════════════════════════════════════
# 小测验：补全缺失的 data 块，让 terraform test 通过
# ══════════════════════════════════════════

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
