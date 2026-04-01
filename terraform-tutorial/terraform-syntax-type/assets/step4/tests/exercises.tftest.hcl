run "check_list_variable" {
  command = plan

  assert {
    condition     = length(output.check_scores) == 4
    error_message = "练习 1 未通过：var.scores 应包含 4 个元素"
  }

  assert {
    condition     = output.check_scores[0] == 90
    error_message = "练习 1 未通过：var.scores 的第一个元素应为 90"
  }

  assert {
    condition     = output.check_scores[3] == 95
    error_message = "练习 1 未通过：var.scores 的最后一个元素应为 95"
  }
}

run "check_map_variable" {
  command = plan

  assert {
    condition     = output.check_labels["app"] == "web"
    error_message = "练习 2 未通过：var.labels[\"app\"] 应为 \"web\""
  }

  assert {
    condition     = output.check_labels["env"] == "prod"
    error_message = "练习 2 未通过：var.labels[\"env\"] 应为 \"prod\""
  }

  assert {
    condition     = output.check_labels["team"] == "backend"
    error_message = "练习 2 未通过：var.labels[\"team\"] 应为 \"backend\""
  }
}

run "check_object_optional" {
  command = plan

  assert {
    condition     = output.check_app_config.name == "my-app"
    error_message = "练习 3 未通过：var.app_config.name 应为 \"my-app\""
  }

  assert {
    condition     = output.check_app_config.replicas == 1
    error_message = "练习 3 未通过：var.app_config.replicas 的默认值应为 1"
  }

  assert {
    condition     = output.check_app_config.debug == false
    error_message = "练习 3 未通过：var.app_config.debug 的默认值应为 false"
  }
}

run "check_expressions" {
  command = plan

  assert {
    condition     = output.check_highest_score == 95
    error_message = "练习 4 未通过：local.highest_score 应为 95（使用 max(var.scores...)）"
  }

  assert {
    condition     = output.check_app_label == "web-prod"
    error_message = "练习 4 未通过：local.app_label 应为 \"web-prod\""
  }

  assert {
    condition     = output.check_replica_count == 1
    error_message = "练习 4 未通过：local.replica_count 应为 1（optional 默认值）"
  }
}
