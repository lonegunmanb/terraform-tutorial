run "check_basic_locals" {
  command = plan

  assert {
    condition     = output.check_app_name == "web-server"
    error_message = "练习 1 未通过：app_name 应为 \"web-server\""
  }

  assert {
    condition     = output.check_app_port == 8080
    error_message = "练习 1 未通过：app_port 应为 8080"
  }
}

run "check_reference" {
  command = plan

  assert {
    condition     = output.check_full_name == "web-server-staging"
    error_message = "练习 2 未通过：full_name 应为 \"web-server-staging\"（app_name + \"-\" + env）"
  }

  assert {
    condition     = output.check_is_production == false
    error_message = "练习 2 未通过：env 为 \"staging\" 时，is_production 应为 false"
  }
}

run "check_complex" {
  command = plan

  assert {
    condition     = output.check_user_count == 3
    error_message = "练习 3 未通过：user_count 应为 3"
  }

  assert {
    condition     = output.check_upper_users[0] == "ALICE"
    error_message = "练习 3 未通过：upper_users 的第一个元素应为 \"ALICE\""
  }

  assert {
    condition     = output.check_upper_users[2] == "CHARLIE"
    error_message = "练习 3 未通过：upper_users 的第三个元素应为 \"CHARLIE\""
  }

  assert {
    condition     = output.check_user_tags["alice"] == "active"
    error_message = "练习 3 未通过：user_tags[\"alice\"] 应为 \"active\""
  }
}

run "check_merge" {
  command = plan

  assert {
    condition     = output.check_merged_tags["App"] == "web-server"
    error_message = "练习 4 未通过：merged_tags[\"App\"] 应为 \"web-server\""
  }

  assert {
    condition     = output.check_merged_tags["Env"] == "staging"
    error_message = "练习 4 未通过：merged_tags[\"Env\"] 应为 \"staging\""
  }

  assert {
    condition     = output.check_merged_tags["Team"] == "platform"
    error_message = "练习 4 未通过：merged_tags[\"Team\"] 应为 \"platform\"（来自 var.custom_tags）"
  }
}
