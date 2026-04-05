# ══════════════════════════════════════════════════════
# 小测验：补全 main.tf 中缺失的 ephemeral 和 local 块，让所有测试通过
# ══════════════════════════════════════════════════════
# 此文件不需要修改。请在 main.tf 中添加缺失的代码。

# ── 测试 1：Secret 创建成功 ──
run "test_secret_created" {
  command = apply

  assert {
    condition     = startswith(output.api_key_secret_arn, "arn:")
    error_message = "Secret ARN 应以 arn: 开头"
  }
}

# ── 测试 2：临时密码长度正确 ──
run "test_ephemeral_password_length" {
  command = apply

  assert {
    condition     = length(output.api_key_length) == 20
    error_message = "临时密码长度应为 20 个字符"
  }
}

# ── 测试 3：Secret ARN 包含名称 ──
run "test_secret_name" {
  command = apply

  assert {
    condition     = strcontains(output.api_key_secret_arn, "quiz-api-key")
    error_message = "Secret ARN 应包含 quiz-api-key"
  }
}
