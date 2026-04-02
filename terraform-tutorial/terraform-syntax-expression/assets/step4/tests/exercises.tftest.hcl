run "check_conditional" {
  command = plan

  assert {
    condition     = output.check_grade == "pass"
    error_message = "练习 1 未通过：score 为 85 时，grade 应为 \"pass\""
  }
}

run "check_for_filter" {
  command = plan

  assert {
    condition     = length(output.check_clean_words) == 3
    error_message = "练习 2 未通过：clean_words 应有 3 个元素（过滤掉空字符串）"
  }

  assert {
    condition     = output.check_clean_words[0] == "HELLO"
    error_message = "练习 2 未通过：第一个元素应为 \"HELLO\"（转为大写）"
  }

  assert {
    condition     = output.check_clean_words[2] == "TERRAFORM"
    error_message = "练习 2 未通过：第三个元素应为 \"TERRAFORM\""
  }
}

run "check_for_map" {
  command = plan

  assert {
    condition     = output.check_user_roles["alice"] == "admin"
    error_message = "练习 3 未通过：user_roles[\"alice\"] 应为 \"admin\""
  }

  assert {
    condition     = output.check_user_roles["bob"] == "dev"
    error_message = "练习 3 未通过：user_roles[\"bob\"] 应为 \"dev\""
  }
}

run "check_splat" {
  command = plan

  assert {
    condition     = length(output.check_user_names) == 3
    error_message = "练习 4 未通过：user_names 应有 3 个元素"
  }

  assert {
    condition     = output.check_user_names[0] == "alice"
    error_message = "练习 4 未通过：第一个元素应为 \"alice\"（使用 splat 表达式）"
  }
}
