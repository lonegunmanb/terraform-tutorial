output "bucket_id" {
  value       = aws_s3_bucket.this.id
  description = "S3 桶的 ID"
}

output "bucket_arn" {
  value       = aws_s3_bucket.this.arn
  description = "S3 桶的 ARN"
}
