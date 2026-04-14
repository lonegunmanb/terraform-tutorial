output "table_name" {
  description = "DynamoDB 表名称"
  value       = aws_dynamodb_table.this.name
}

output "table_arn" {
  description = "DynamoDB 表 ARN"
  value       = aws_dynamodb_table.this.arn
}
