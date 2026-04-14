output "queue_url" {
  description = "SQS 队列 URL"
  value       = aws_sqs_queue.this.url
}

output "queue_arn" {
  description = "SQS 队列 ARN（用于 IAM 策略）"
  value       = aws_sqs_queue.this.arn
}

output "dlq_arn" {
  description = "死信队列 ARN"
  value       = aws_sqs_queue.dead_letter.arn
}
