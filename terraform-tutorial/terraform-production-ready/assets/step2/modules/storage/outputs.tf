output "static_bucket_name" {
  value = aws_s3_bucket.static.bucket
}

output "static_bucket_arn" {
  value = aws_s3_bucket.static.arn
}

output "backup_bucket_name" {
  value = aws_s3_bucket.backups.bucket
}

output "backup_bucket_arn" {
  value = aws_s3_bucket.backups.arn
}
