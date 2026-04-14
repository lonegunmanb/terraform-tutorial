# 数据与消息层：DynamoDB + SQS + SNS
# 对应三层架构中的数据层和应用层间的异步通信

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

resource "aws_sqs_queue" "dlq" {
  name                      = "${var.app_name}-${var.environment}-tasks-dlq"
  message_retention_seconds = 1209600
}

resource "aws_sqs_queue" "tasks" {
  name                       = "${var.app_name}-${var.environment}-tasks"
  visibility_timeout_seconds = 60
  message_retention_seconds  = var.message_retention_seconds
}

resource "aws_sqs_queue_redrive_policy" "tasks" {
  queue_url = aws_sqs_queue.tasks.id
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 5
  })
}

resource "aws_sns_topic" "alerts" {
  name = "${var.app_name}-${var.environment}-alerts"
}

resource "aws_sns_topic_subscription" "alerts_to_queue" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.tasks.arn
}

resource "aws_sqs_queue_policy" "allow_sns" {
  queue_url = aws_sqs_queue.tasks.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "sns.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.tasks.arn
      Condition = {
        ArnEquals = { "aws:SourceArn" = aws_sns_topic.alerts.arn }
      }
    }]
  })
}
