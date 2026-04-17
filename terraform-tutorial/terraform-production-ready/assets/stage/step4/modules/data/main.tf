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

  lifecycle {
    postcondition {
      condition     = self.billing_mode == "PAY_PER_REQUEST"
      error_message = "用户数据表必须使用 PAY_PER_REQUEST 计费模式，避免预置容量浪费。"
    }
  }
}
