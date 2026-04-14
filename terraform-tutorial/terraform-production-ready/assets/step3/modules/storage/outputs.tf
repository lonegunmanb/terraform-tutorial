# outputs.tf（step3：适配 terraform-aws-modules/s3-bucket 的输出属性名）

output "bucket_name" {
  description = "存储桶名称"
  value       = module.s3_bucket.s3_bucket_id
}

output "bucket_arn" {
  description = "存储桶 ARN（用于 IAM 策略）"
  value       = module.s3_bucket.s3_bucket_arn
}

output "bucket_id" {
  description = "存储桶 ID"
  value       = module.s3_bucket.s3_bucket_id
}
