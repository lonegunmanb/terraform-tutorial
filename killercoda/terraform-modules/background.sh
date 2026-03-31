#!/bin/bash

# --- Install Terraform CLI (direct binary) ---
TF_VERSION="1.7.5"
curl -fsSL "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip" -o /tmp/terraform.zip
apt-get update -qq && apt-get install -y -qq unzip curl > /dev/null 2>&1
unzip -o /tmp/terraform.zip -d /usr/local/bin/ > /dev/null 2>&1
rm /tmp/terraform.zip
chmod +x /usr/local/bin/terraform

# --- Ensure workspace directory exists ---
mkdir -p /root/workspace/modules/s3-bucket

# --- Start LocalStack via Docker Compose ---
cd /root/workspace

# Create docker-compose.yml if not provided by assets
if [ ! -f docker-compose.yml ]; then
cat > docker-compose.yml <<'EOF'
services:
  localstack:
    image: localstack/localstack:3
    ports:
      - "4566:4566"
    environment:
      - SERVICES=s3
      - DEFAULT_REGION=us-east-1
      - EAGER_SERVICE_LOADING=1
    deploy:
      resources:
        limits:
          memory: 1536M
EOF
fi

# Create main.tf if not provided by assets
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

  endpoints {
    s3  = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}

module "app_data" {
  source      = "./modules/s3-bucket"
  bucket_name = "my-app-data"
  environment = "dev"
  tags        = { Team = "backend" }
}

# module "app_logs" {
#   source      = "./modules/s3-bucket"
#   bucket_name = "my-app-logs"
#   environment = "dev"
#   tags        = { Team = "platform" }
# }

output "data_bucket_id" {
  value = module.app_data.bucket_id
}

# output "logs_bucket_id" {
#   value = module.app_logs.bucket_id
# }
EOTF
fi

# Create module files if not provided by assets
if [ ! -f modules/s3-bucket/main.tf ]; then
cat > modules/s3-bucket/main.tf <<'EOTF'
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  tags = merge(
    { Environment = var.environment, ManagedBy = "Terraform" },
    var.tags,
  )
}
EOTF
cat > modules/s3-bucket/variables.tf <<'EOTF'
variable "bucket_name" {
  type        = string
  description = "The name of the S3 bucket"
}
variable "environment" {
  type        = string
  default     = "dev"
  description = "The deployment environment (dev, staging, prod)"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}
variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags to apply to the bucket"
}
EOTF
cat > modules/s3-bucket/outputs.tf <<'EOTF'
output "bucket_id" {
  value       = aws_s3_bucket.this.id
  description = "The ID of the created S3 bucket"
}
output "bucket_arn" {
  value       = aws_s3_bucket.this.arn
  description = "The ARN of the created S3 bucket"
}
EOTF
fi

docker-compose up -d 2>&1

echo "Waiting for LocalStack to be ready..."
for i in $(seq 1 30); do
  if curl -sf http://localhost:4566/_localstack/health > /dev/null 2>&1; then
    echo "LocalStack is ready."
    break
  fi
  sleep 2
done

# --- Signal completion ---
touch /tmp/.setup-done
