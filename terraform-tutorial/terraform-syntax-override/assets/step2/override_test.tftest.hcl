run "test_instance_count_overridden" {
  command = plan

  assert {
    condition     = var.instance_count == 3
    error_message = "第 1 题：instance_count 应被重载为 3，当前值为 ${var.instance_count}"
  }
}

run "test_environment_overridden" {
  command = apply

  assert {
    condition     = output.environment == "prod"
    error_message = "第 2 题：environment 应被重载为 \"prod\"，当前值为 \"${output.environment}\""
  }
}

run "test_prefix_reflects_override" {
  command = apply

  assert {
    condition     = output.prefix == "webapp-prod"
    error_message = "第 2 题（验证）：prefix 应为 \"webapp-prod\"，当前值为 \"${output.prefix}\""
  }
}

run "test_queue_visibility_timeout" {
  command = apply

  assert {
    condition     = output.queue_visibility_timeout == 60
    error_message = "第 3 题：SQS 队列的 visibility_timeout_seconds 应被重载为 60，当前值为 ${output.queue_visibility_timeout}"
  }
}

run "test_queue_name_uses_prod" {
  command = apply

  assert {
    condition     = output.queue_name == "webapp-prod-tasks"
    error_message = "综合验证：队列名称应为 \"webapp-prod-tasks\"，当前值为 \"${output.queue_name}\""
  }
}

run "test_bucket_uses_prod_prefix" {
  command = apply

  assert {
    condition     = output.bucket_id == "webapp-prod-artifacts"
    error_message = "综合验证：桶 ID 应为 \"webapp-prod-artifacts\"，当前值为 \"${output.bucket_id}\""
  }
}
