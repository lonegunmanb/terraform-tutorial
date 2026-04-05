run "web_assets_bucket" {
  command = apply

  assert {
    condition     = module.web_assets.bucket_id == "quiz-web-assets"
    error_message = "module.web_assets 的 bucket_id 应为 quiz-web-assets"
  }

  assert {
    condition     = module.web_assets.bucket_arn != null && module.web_assets.bucket_arn != ""
    error_message = "module.web_assets 应输出 bucket_arn"
  }
}

run "api_data_bucket" {
  command = apply

  assert {
    condition     = module.api_data.bucket_id == "quiz-api-data"
    error_message = "module.api_data 的 bucket_id 应为 quiz-api-data"
  }

  assert {
    condition     = module.api_data.bucket_arn != null && module.api_data.bucket_arn != ""
    error_message = "module.api_data 应输出 bucket_arn"
  }
}

run "backups_bucket" {
  command = apply

  assert {
    condition     = module.backups.bucket_id == "quiz-backups"
    error_message = "module.backups 的 bucket_id 应为 quiz-backups"
  }
}

run "outputs_correct" {
  command = apply

  assert {
    condition     = output.web_assets_id == "quiz-web-assets"
    error_message = "output web_assets_id 应为 quiz-web-assets"
  }

  assert {
    condition     = output.api_data_arn != null && output.api_data_arn != ""
    error_message = "output api_data_arn 不应为空"
  }

  assert {
    condition     = output.backups_id == "quiz-backups"
    error_message = "output backups_id 应为 quiz-backups"
  }

  assert {
    condition     = length(output.all_bucket_ids) == 3
    error_message = "output all_bucket_ids 应包含 3 个元素"
  }

  assert {
    condition     = output.all_bucket_ids[0] == "quiz-web-assets"
    error_message = "all_bucket_ids[0] 应为 quiz-web-assets"
  }

  assert {
    condition     = output.all_bucket_ids[1] == "quiz-api-data"
    error_message = "all_bucket_ids[1] 应为 quiz-api-data"
  }

  assert {
    condition     = output.all_bucket_ids[2] == "quiz-backups"
    error_message = "all_bucket_ids[2] 应为 quiz-backups"
  }
}
