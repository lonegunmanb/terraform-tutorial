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
