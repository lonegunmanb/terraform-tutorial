terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = "test"
  secret_key = "test"

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    secretsmanager = "http://localhost:4566"
    sts            = "http://localhost:4566"
  }
}

# ══════════════════════════════════════════
# 场景：用临时资源安全地为 Secret 注入密码
# ══════════════════════════════════════════

# ── 1. 用 ephemeral 生成密码（不保存到状态文件）──
ephemeral "random_password" "db_password" {
  length           = 24
  special          = true
  override_special = "!#$%^&*()-_=+"
}

# ── 2. 通过 local 中转临时值 ──
locals {
  db_credentials = jsonencode({
    username = "admin"
    password = ephemeral.random_password.db_password.result
    host     = "db.internal.example.com"
    port     = 5432
  })
}

# ── 3. 创建 Secrets Manager Secret ──
resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "prod/db-credentials"
  description = "Database credentials for production"
}

# ── 4. 用 write_only_attributes 安全注入密码 ──
# aws_secretsmanager_secret_version 的 secret_string_wo 属性
# 是 write-only 属性：值会发送给 API 但不会保存到状态文件。
# 搭配 ephemeral 生成的密码，实现端到端的"状态文件零敏感数据"。
resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id     = aws_secretsmanager_secret.db_credentials.id
  secret_string_wo = local.db_credentials
  secret_string_wo_version = 1
}

# ── 对比：用普通 resource 生成的密码 ──
resource "random_password" "db_password_resource" {
  length           = 24
  special          = true
  override_special = "!#$%^&*()-_=+"
}

resource "aws_secretsmanager_secret" "db_credentials_insecure" {
  name        = "prod/db-credentials-insecure"
  description = "Database credentials (insecure - password in state)"
}

resource "aws_secretsmanager_secret_version" "db_credentials_insecure" {
  secret_id     = aws_secretsmanager_secret.db_credentials_insecure.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.db_password_resource.result
    host     = "db.internal.example.com"
    port     = 5432
  })
}

# ── 输出 ──
output "secure_secret_arn" {
  value       = aws_secretsmanager_secret.db_credentials.arn
  description = "安全方式创建的 Secret ARN"
}

output "insecure_secret_arn" {
  value       = aws_secretsmanager_secret.db_credentials_insecure.arn
  description = "不安全方式创建的 Secret ARN"
}
