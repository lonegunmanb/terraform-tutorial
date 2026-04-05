run "module_creates_bucket" {
  command = plan

  assert {
    condition     = module.quiz.bucket_id == "quiz-bucket"
    error_message = "模块输出 bucket_id 应为 quiz-bucket"
  }

  assert {
    condition     = module.quiz.bucket_arn != null && module.quiz.bucket_arn != ""
    error_message = "模块应输出 bucket_arn"
  }
}
