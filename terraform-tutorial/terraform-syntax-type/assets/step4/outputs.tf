# 此文件用于测试验证，请勿修改

output "check_scores" {
  value = var.scores
}

output "check_labels" {
  value = var.labels
}

output "check_app_config" {
  value = var.app_config
}

output "check_highest_score" {
  value = local.highest_score
}

output "check_app_label" {
  value = local.app_label
}

output "check_replica_count" {
  value = local.replica_count
}
