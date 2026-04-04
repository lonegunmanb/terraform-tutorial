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
