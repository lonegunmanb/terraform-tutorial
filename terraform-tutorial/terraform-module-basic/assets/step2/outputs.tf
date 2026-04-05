output "data_bucket_id" {
  value = aws_s3_bucket.data.id
}

output "logs_bucket_id" {
  value = aws_s3_bucket.logs.id
}
