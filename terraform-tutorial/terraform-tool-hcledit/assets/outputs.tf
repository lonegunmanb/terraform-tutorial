output "app_bucket" {
  value       = aws_s3_bucket.app.bucket
  description = "应用数据桶名称"
}

output "logs_bucket" {
  value       = aws_s3_bucket.logs.bucket
  description = "日志桶名称"
}

output "sessions_table" {
  value       = aws_dynamodb_table.sessions.name
  description = "会话表名称"
}
