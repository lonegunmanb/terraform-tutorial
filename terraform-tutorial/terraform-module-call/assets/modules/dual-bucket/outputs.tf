output "primary_id" {
  value = aws_s3_bucket.primary.id
}

output "replica_id" {
  value = aws_s3_bucket.replica.id
}
