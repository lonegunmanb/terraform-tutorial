#!/bin/bash
exec > /tmp/background.log 2>&1
set -x

source /root/setup-common.sh

# ── 1. Seed workspace files (fallback if assets copy fails) ──
mkdir -p /root/workspace
cd /root/workspace

if [ ! -f docker-compose.yml ]; then
cat > docker-compose.yml <<'EOF'
services:
  localstack:
    image: localstack/localstack:3
    ports:
      - "4566:4566"
    environment:
      - SERVICES=s3,iam,ec2
      - DEFAULT_REGION=us-east-1
      - EAGER_SERVICE_LOADING=1
    deploy:
      resources:
        limits:
          memory: 1536M
EOF
fi

if [ ! -f main.tf ]; then
cat > main.tf <<'EOTF'
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
    iam = "http://localhost:4566"
    ec2 = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}

variable "BucketName" {
  type    = string
  default = "my-lint-test-bucket"
}

variable "unused_region" {
  type        = string
  default     = "us-west-2"
  description = "This variable is never referenced anywhere"
}

resource "aws_s3_bucket" "example" {
  bucket = var.BucketName
  tags = {
    Name = "Lint Test Bucket"
  }
}

output "bucket_domain" {
  value       = aws_s3_bucket.example.bucket_domain_name
  description = "The domain name of the bucket (deprecated attribute)"
}
EOTF
fi

if [ ! -f .tflint.hcl ]; then
cat > .tflint.hcl <<'EOHCL'
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}
rule "terraform_naming_convention" {
  enabled = true
}
rule "terraform_documented_variables" {
  enabled = true
}
rule "terraform_unused_declarations" {
  enabled = true
}
EOHCL
fi

# ── 2. Install tools & start services ──
install_terraform
install_tflint
start_localstack
finish_setup
