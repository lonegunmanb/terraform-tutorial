#!/bin/bash

# --- Install tenv (Terraform version manager) ---
TENV_VERSION="v4.9.3"
curl -fsSL "https://github.com/tofuutils/tenv/releases/download/${TENV_VERSION}/tenv_${TENV_VERSION#v}_amd64.deb" -o /tmp/tenv.deb
dpkg -i /tmp/tenv.deb > /dev/null 2>&1
rm /tmp/tenv.deb

# --- Install Terraform + TFLint via tenv ---
tenv terraform install latest > /dev/null 2>&1
tenv terraform use latest > /dev/null 2>&1
tenv tflint install latest > /dev/null 2>&1
tenv tflint use latest > /dev/null 2>&1

# --- Ensure workspace directory exists ---
mkdir -p /root/workspace

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
      - SERVICES=s3,iam,dynamodb,ec2
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
fi

docker-compose up -d 2>&1

# Wait for LocalStack to be healthy
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
