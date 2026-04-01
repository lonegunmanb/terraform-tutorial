run "check_locals" {
  command = plan

  assert {
    condition     = output.check_project_name == "terraform-tutorial"
    error_message = "练习 1 未通过：local.project_name 应为 \"terraform-tutorial\""
  }

  assert {
    condition     = output.check_environment == "lab"
    error_message = "练习 1 未通过：local.environment 应为 \"lab\""
  }
}

run "check_heredoc" {
  command = plan

  assert {
    condition     = can(regex("listen 80", output.check_server_config))
    error_message = "练习 2 未通过：local.server_config 应包含 \"listen 80\"（使用 heredoc 语法）"
  }

  assert {
    condition     = can(regex("server_name example\\.com", output.check_server_config))
    error_message = "练习 2 未通过：local.server_config 应包含 \"server_name example.com\""
  }
}

run "check_interpolation" {
  command = plan

  assert {
    condition     = output.project_info == "terraform-tutorial-lab"
    error_message = "练习 3 未通过：output.project_info 应为 \"terraform-tutorial-lab\"（使用字符串插值）"
  }
}
