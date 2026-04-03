run "check_basic_output" {
  command = plan

  assert {
    condition     = output.project == "my-app"
    error_message = "练习 1 未通过：output \"project\" 的值应为 \"my-app\""
  }

  assert {
    condition     = output.deployment_region == "us-east-1"
    error_message = "练习 1 未通过：output \"deployment_region\" 的值应为 \"us-east-1\""
  }
}

run "check_expression_output" {
  command = plan

  assert {
    condition     = output.resource_prefix == "my-app-us-east-1"
    error_message = "练习 2 未通过：output \"resource_prefix\" 的值应为 \"my-app-us-east-1\""
  }
}

run "check_sensitive_output" {
  command = plan

  assert {
    condition     = nonsensitive(output.db_connection_url) == "postgresql://admin:s3cret!Pass@localhost:5432/mydb"
    error_message = "练习 3 未通过：output \"db_connection_url\" 的值应为 \"postgresql://admin:s3cret!Pass@localhost:5432/mydb\"，且必须标记为 sensitive"
  }
}

run "check_precondition_output" {
  command = plan

  assert {
    condition     = output.primary_server_ip == "10.0.0.1"
    error_message = "练习 4 未通过：output \"primary_server_ip\" 的值应为 \"10.0.0.1\"（server_count=3 时第一个服务器的 IP）"
  }
}
