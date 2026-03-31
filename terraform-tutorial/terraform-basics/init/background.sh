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
      - SERVICES=ec2
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
    ec2 = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}

resource "aws_instance" "tutorial" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  tags = {
    Name = "TerraformTutorial"
  }
}

output "instance_id" {
  value       = aws_instance.tutorial.id
  description = "The ID of the EC2 instance"
}

output "instance_type" {
  value       = aws_instance.tutorial.instance_type
  description = "The instance type of the EC2 instance"
}
EOTF
fi

# ── 2. Install tools & start services ──
# Start LocalStack first (docker pull runs in background)
cd /root/workspace
docker compose up -d

# Install tools while LocalStack is starting
install_terraform
install_awscli

# Now wait for LocalStack to be healthy
echo "Waiting for LocalStack to be ready..."
for i in $(seq 1 60); do
  if curl -sf http://localhost:4566/_localstack/health > /dev/null 2>&1; then
    echo "LocalStack is ready."
    break
  fi
  sleep 2
done

finish_setup
