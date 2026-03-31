#!/bin/bash
# Log everything for debugging — check /tmp/background.log if something fails
exec > /tmp/background.log 2>&1
set -x

# ── 1. Create workspace and seed files FIRST (no network needed) ──
mkdir -p /root/workspace
cd /root/workspace

cat > docker-compose.yml <<'EOF'
services:
  localstack:
    image: localstack/localstack:3
    ports:
      - "4566:4566"
    environment:
      - SERVICES=s3,iam,dynamodb,ec2
      - DEFAULT_REGION=us-east-1
      - EAGER_SERVICE_LOADING=1
    deploy:
      resources:
        limits:
          memory: 1536M
EOF

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
    s3       = "http://localhost:4566"
    iam      = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
    sts      = "http://localhost:4566"
    ec2      = "http://localhost:4566"
  }
}

resource "aws_s3_bucket" "tutorial" {
  bucket = "my-terraform-tutorial-bucket"

  tags = {
    Name        = "Tutorial Bucket"
    Environment = "Lab"
    ManagedBy   = "Terraform"
  }
}

output "bucket_name" {
  value       = aws_s3_bucket.tutorial.bucket
  description = "The name of the S3 bucket created by Terraform"
}
EOTF

# ── 2. Install Terraform (direct binary from HashiCorp CDN) ──
apt-get update -qq && apt-get install -y -qq unzip > /dev/null 2>&1

TERRAFORM_VERSION="1.14.8"
curl --connect-timeout 10 --max-time 120 -fsSL \
  "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" \
  -o /tmp/terraform.zip \
  && unzip -o -q /tmp/terraform.zip -d /usr/local/bin/ \
  && chmod +x /usr/local/bin/terraform \
  && rm -f /tmp/terraform.zip

terraform version || echo "WARNING: terraform install failed"

# ── 3. Start LocalStack ──
cd /root/workspace
docker compose up -d

for i in $(seq 1 30); do
  curl -sf http://localhost:4566/_localstack/health > /dev/null 2>&1 && break
  sleep 2
done

# ── 4. Signal done ──
touch /tmp/.setup-done
