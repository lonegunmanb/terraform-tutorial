#!/bin/bash
exec > /tmp/background.log 2>&1
set -x

source /root/setup-common.sh

# ── 1. Seed workspace files ──
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
      - SERVICES=ec2,sts
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

  endpoints {
    ec2 = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.16.0"

  name = "demo-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a"]
  private_subnets = ["10.0.1.0/24"]
  public_subnets  = ["10.0.101.0/24"]

  # 关闭 LocalStack 模拟不准确的默认资源管理
  manage_default_network_acl    = false
  manage_default_route_table    = false
  manage_default_security_group = false

  tags = {
    Project   = "mapotf-demo"
    ManagedBy = "Terraform"
  }
}
EOTF
fi

# ── 2. Install tooling ──
install_terraform
install_awscli
start_localstack

# ── 3. Install Go and mapotf ──
echo "安装 Go..."
GO_VERSION="1.23.0"
curl -sSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" | tar xz -C /usr/local
export PATH=$PATH:/usr/local/go/bin:/root/go/bin
echo 'export PATH=$PATH:/usr/local/go/bin:/root/go/bin' >> /root/.bashrc

echo "安装 mapotf..."
GOBIN=/usr/local/bin go install github.com/Azure/mapotf@latest

# ── 4. Initialize Terraform (download VPC module + providers) ──
cd /root/workspace
terraform init

# ── 5. Start auto-tag daemon ──
# This simulates an AWS environment where VPCs get auto-tagged by compliance policies
nohup /root/auto-tag-vpc.sh &

install_theia_plugin
finish_setup
