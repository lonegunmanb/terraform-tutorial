terraform {
  required_version = ">= 1.10"
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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
# 小测验：补全缺失的 ephemeral 块和 local，让 terraform test 通过
# ══════════════════════════════════════════

# ── 资源（已提供，不要修改）──

resource "aws_secretsmanager_secret" "api_key" {
  name = "quiz-api-key"
}

# ── 第 1 题 ──
# 添加一个 ephemeral 块，用 random_password 生成一个 20 字符的密码
# 类型：random_password，名称：api_key
# 参数：length = 20, special = false
#
# 在下方写你的代码：


# ── 第 2 题 ──
# 添加一个 locals 块，将临时密码赋给 local.api_key_value
# 提示：引用 ephemeral.random_password.api_key.result
#
# 在下方写你的代码：


# ── 第 3 题 ──
# 使用 write-only 属性将密码安全地写入 Secret
# 补全下面的 aws_secretsmanager_secret_version 资源块
# 提示：使用 secret_string_wo 和 secret_string_wo_version 属性
#        secret_string_wo 应引用 local.api_key_value
#
# 在下方写你的代码：
# resource "aws_secretsmanager_secret_version" "api_key" {
#   secret_id                = aws_secretsmanager_secret.api_key.id
#   在此补全 write-only 属性
# }


# ── 输出（已提供，不要修改）──

output "api_key_secret_arn" {
  value = aws_secretsmanager_secret.api_key.arn
}
