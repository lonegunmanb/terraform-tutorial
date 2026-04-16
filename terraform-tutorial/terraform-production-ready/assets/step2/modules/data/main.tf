# 数据层：DynamoDB

resource "aws_dynamodb_table" "users" {
  name         = "${var.app_name}-${var.environment}-users"
  billing_mode = var.billing_mode
  hash_key     = "UserId"
  range_key    = "CreatedAt"

  attribute {
    name = "UserId"
    type = "S"
  }

  attribute {
    name = "CreatedAt"
    type = "S"
  }
}
