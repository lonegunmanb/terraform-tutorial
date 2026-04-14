output "users_table_name" {
  value = aws_dynamodb_table.users.name
}

output "users_table_arn" {
  value = aws_dynamodb_table.users.arn
}

output "task_queue_url" {
  value = aws_sqs_queue.tasks.url
}

output "task_queue_arn" {
  value = aws_sqs_queue.tasks.arn
}

output "alert_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "db_secret_arn" {
  value = ""
}
