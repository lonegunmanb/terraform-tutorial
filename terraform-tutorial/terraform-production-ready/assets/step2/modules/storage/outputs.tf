output "bucket_name" {
  description = "存储桶名称"
  value       = aws_s3_bucket.this.bucket
}

output "bucket_arn" {
  description = "存储桶 ARN（用于 IAM 策略）"
  value       = aws_s3_bucket.this.arn
}

output "bucket_id" {
  description = "存储桶 ID"
  value       = aws_s3_bucket.this.id
}
