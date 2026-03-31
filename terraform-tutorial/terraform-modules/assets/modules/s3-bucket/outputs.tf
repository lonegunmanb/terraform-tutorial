output "bucket_id" {
  value       = aws_s3_bucket.this.id
  description = "The ID of the created S3 bucket"
}

output "bucket_arn" {
  value       = aws_s3_bucket.this.arn
  description = "The ARN of the created S3 bucket"
}
