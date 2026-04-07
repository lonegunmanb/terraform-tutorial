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

# ── 练习：使用 import 块将已有的 S3 桶纳入 Terraform 管理 ──
# 环境中已经存在两个通过 awslocal 手动创建的桶：
#   - legacy-app-data
#   - legacy-app-logs
#
# 请在下方添加 resource 块和 import 块来导入它们。
