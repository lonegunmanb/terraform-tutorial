# modules/database/main.tf（step4：加入 postcondition）

resource "aws_dynamodb_table" "this" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = var.hash_key
  range_key    = var.range_key

  attribute {
    name = var.hash_key
    type = "S"
  }

  attribute {
    name = var.range_key
    type = "S"
  }

  # postcondition 在 apply 之后验证"此模块对外的行为保证"：
  # 不管未来的重构是否修改了 billing_mode，这个断言都会在 apply 后告警。
  lifecycle {
    postcondition {
      condition     = self.billing_mode == "PAY_PER_REQUEST"
      error_message = "审计日志表必须使用 PAY_PER_REQUEST 按需计费，以避免预置容量浪费。请勿修改 billing_mode。"
    }
  }
}
