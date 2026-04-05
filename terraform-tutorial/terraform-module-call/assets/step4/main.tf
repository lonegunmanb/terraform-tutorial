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
# 测验：综合模块调用
#
# 要求：
# 1. 调用 ../modules/s3-bucket 模块，创建 3 个桶：
#    - 模块名称: web_assets，bucket_name: "quiz-web-assets"，tags: { Role = "frontend" }
#    - 模块名称: api_data，  bucket_name: "quiz-api-data"，  tags: { Role = "backend" }
#    - 模块名称: backups，   bucket_name: "quiz-backups"，   tags: { Role = "ops" }
#
# 2. 定义以下 output：
#    - web_assets_id:  值为 module.web_assets.bucket_id
#    - api_data_arn:   值为 module.api_data.bucket_arn
#    - backups_id:     值为 module.backups.bucket_id
#    - all_bucket_ids: 值为包含三个桶 bucket_id 的列表
#                      （顺序：web_assets, api_data, backups）
# ══════════════════════════════════════════

# TODO: 在下方编写你的代码
