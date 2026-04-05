terraform {
  required_version = ">= 1.0"
  required_providers {
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
    s3  = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}

# ══════════════════════════════════════════
# 测验：请在 modules/storage 目录下创建一个模块
#
# 要求：
# 1. 模块接受一个 string 类型的输入变量 bucket_name
# 2. 模块创建一个 aws_s3_bucket 资源，名称为 bucket_name 的值
# 3. 模块输出 bucket_id（桶的 id）和 bucket_arn（桶的 arn）
#
# 然后在下方调用该模块，创建一个名为 "quiz-bucket" 的桶
# ══════════════════════════════════════════

# TODO: 在这里用 module 块调用 modules/storage 模块
