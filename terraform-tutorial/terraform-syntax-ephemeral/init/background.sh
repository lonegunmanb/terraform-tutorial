#!/bin/bash
exec > /tmp/background.log 2>&1
set -x

source /root/setup-common.sh

# ── 1. Ensure workspace directories exist ──
mkdir -p /root/workspace/step1
mkdir -p /root/workspace/step2
mkdir -p /root/workspace/step3

# ── 2. Seed workspace files (fallback if assets copy fails) ──

if [ ! -f /root/workspace/step1/main.tf ]; then
cat > /root/workspace/step1/main.tf <<'EOTF'
terraform {
  required_version = ">= 1.10"
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# ══════════════════════════════════════════
# 对比实验：resource vs ephemeral
# 同样使用 random_password，观察状态文件中的差异
# ══════════════════════════════════════════

# ── 方式 1：普通资源（密码会保存到状态文件）──
resource "random_password" "resource_password" {
  length  = 16
  special = true
}

# 普通资源的密码可以通过 output 输出
output "resource_password" {
  value     = random_password.resource_password.result
  sensitive = true
}

# ── 方式 2：临时资源（密码不会保存到状态文件）──
ephemeral "random_password" "ephemeral_password" {
  length  = 16
  special = true
}

# 临时资源的值只能通过 local 中转
locals {
  eph_password = ephemeral.random_password.ephemeral_password.result
}

# 临时 output（仅用于演示，不会持久化）
output "ephemeral_password" {
  value     = local.eph_password
  ephemeral = true
}
EOTF
fi

if [ ! -f /root/workspace/step2/main.tf ]; then
cat > /root/workspace/step2/main.tf <<'EOTF'
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
EOTF
fi

if [ ! -f /root/workspace/step3/main.tf ]; then
cat > /root/workspace/step3/main.tf <<'EOTF'
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
EOTF
fi

if [ ! -f /root/workspace/step3/ephemeral_test.tftest.hcl ]; then
cat > /root/workspace/step3/ephemeral_test.tftest.hcl <<'EOTF'
# ══════════════════════════════════════════════════════
# 小测验：补全 main.tf 中缺失的 ephemeral 和 local 块，让所有测试通过
# ══════════════════════════════════════════════════════
# 此文件不需要修改。请在 main.tf 中添加缺失的代码。

# ── 测试 1：Secret 创建成功 ──
run "test_secret_created" {
  command = apply

  assert {
    condition     = startswith(output.api_key_secret_arn, "arn:")
    error_message = "Secret ARN 应以 arn: 开头"
  }
}

# ── 测试 2：Secret ARN 包含名称 ──
run "test_secret_name" {
  command = apply

  assert {
    condition     = strcontains(output.api_key_secret_arn, "quiz-api-key")
    error_message = "Secret ARN 应包含 quiz-api-key"
  }
}
EOTF
fi

# ── 3. Install tools ──
install_terraform
install_awscli

# ── 4. Start LocalStack ──
start_localstack

# ── 5. Pre-init all steps ──
cd /root/workspace/step1
terraform init

cd /root/workspace/step2
terraform init

cd /root/workspace/step3
terraform init

# ── 6. Signal completion ──
finish_setup
