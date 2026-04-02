run "create_instance_with_defaults" {
  command = apply

  assert {
    condition     = output.check_instance_id != ""
    error_message = "练习 4 未通过：EC2 实例未成功创建（instance_id 为空）"
  }

  assert {
    condition     = output.check_instance_type == "t2.micro"
    error_message = "练习 2/4 未通过：instance_type 应为 \"t2.micro\""
  }

  assert {
    condition     = output.check_instance_name == "my-tutorial-vm"
    error_message = "练习 1 未通过：var.instance_name 的默认值应为 \"my-tutorial-vm\""
  }

  assert {
    condition     = nonsensitive(output.check_owner) == "ops-team"
    error_message = "练习 3 未通过：var.owner 的默认值应为 \"ops-team\""
  }
}

run "validate_instance_name_length" {
  command = plan

  variables {
    instance_name = "ab"
  }

  expect_failures = [
    var.instance_name,
  ]
}

run "validate_instance_type_enum" {
  command = plan

  variables {
    instance_type = "t2.xlarge"
  }

  expect_failures = [
    var.instance_type,
  ]
}

run "create_instance_with_custom_vars" {
  command = apply

  variables {
    instance_name = "custom-server"
    instance_type = "t2.small"
    owner         = "dev-team"
  }

  assert {
    condition     = output.check_instance_id != ""
    error_message = "自定义变量创建实例失败"
  }

  assert {
    condition     = output.check_instance_type == "t2.small"
    error_message = "instance_type 应为传入的 \"t2.small\""
  }

  assert {
    condition     = output.check_instance_name == "custom-server"
    error_message = "instance_name 应为传入的 \"custom-server\""
  }

  assert {
    condition     = nonsensitive(output.check_owner) == "dev-team"
    error_message = "owner 应为传入的 \"dev-team\""
  }
}
