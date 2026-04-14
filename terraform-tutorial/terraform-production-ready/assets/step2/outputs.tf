output "config_bucket_name" {
  description = "配置文件 S3 存储桶名称"
  value       = module.storage.bucket_name
}

output "notification_queue_url" {
  description = "变更通知 SQS 队列 URL"
  value       = module.queue.queue_url
}

output "audit_table_name" {
  description = "审计日志 DynamoDB 表名称"
  value       = module.database.table_name
}

output "app_policy_arn" {
  description = "应用访问 IAM 策略 ARN"
  value       = aws_iam_policy.app_reader.arn
}
