#!/bin/bash

# --- Install Terraform CLI (direct binary) ---
TF_VERSION="1.7.5"
curl -fsSL "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip" -o /tmp/terraform.zip
apt-get update -qq && apt-get install -y -qq unzip curl > /dev/null 2>&1
unzip -o /tmp/terraform.zip -d /usr/local/bin/ > /dev/null 2>&1
rm /tmp/terraform.zip
chmod +x /usr/local/bin/terraform

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
      - SERVICES=s3,iam,dynamodb
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
  }
}

resource "aws_s3_bucket" "data" {
  bucket = "my-app-data-bucket"
  tags = {
    Name        = "Data Bucket"
    Environment = "Lab"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket" "logs" {
  bucket = "my-app-logs-bucket"
  tags = {
    Name        = "Logs Bucket"
    Environment = "Lab"
    ManagedBy   = "Terraform"
  }
}

resource "aws_dynamodb_table" "locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = {
    Name      = "Terraform Lock Table"
    ManagedBy = "Terraform"
  }
}

output "data_bucket" {
  value = aws_s3_bucket.data.bucket
}
output "logs_bucket" {
  value = aws_s3_bucket.logs.bucket
}
output "lock_table" {
  value = aws_dynamodb_table.locks.name
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

# --- Pre-apply infrastructure so students have state to explore ---
cd /root/workspace
terraform init -input=false > /dev/null 2>&1
terraform apply -auto-approve -input=false > /dev/null 2>&1

# --- Signal completion ---
touch /tmp/.setup-done
