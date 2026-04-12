output "bucket_id" {
  value       = aws_s3_bucket.website.id
  description = "The ID of the S3 bucket."
}

output "bucket_arn" {
  value       = aws_s3_bucket.website.arn
  description = "The ARN of the S3 bucket."
}

output "website_endpoint" {
  value       = aws_s3_bucket_website_configuration.website.website_endpoint
  description = "The website endpoint URL of the S3 bucket."
}

output "website_domain" {
  value       = aws_s3_bucket_website_configuration.website.website_domain
  description = "The domain of the website endpoint."
}
