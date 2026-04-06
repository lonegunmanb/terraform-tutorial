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

# ── 使用 count 批量调用模块 ──

variable "bucket_names" {
  type    = list(string)
  default = ["alpha", "beta", "gamma"]
}

module "buckets_count" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.11.0"

  count         = length(var.bucket_names)
  bucket        = "count-${var.bucket_names[count.index]}"
  force_destroy = true

  tags = {
    Index = count.index
  }
}

output "count_bucket_ids" {
  value = module.buckets_count[*].s3_bucket_id
}

# ── 使用 for_each 批量调用模块 ──

variable "environments" {
  type = map(object({
    suffix = string
    tags   = map(string)
  }))
  default = {
    dev = {
      suffix = "dev"
      tags   = { Environment = "dev" }
    }
    staging = {
      suffix = "staging"
      tags   = { Environment = "staging" }
    }
    prod = {
      suffix = "prod"
      tags   = { Environment = "prod" }
    }
  }
}

module "env_buckets" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.11.0"

  for_each      = var.environments
  bucket        = "app-${each.value.suffix}"
  force_destroy = true

  tags = each.value.tags
}

output "env_bucket_ids" {
  value = { for k, v in module.env_buckets : k => v.s3_bucket_id }
}
