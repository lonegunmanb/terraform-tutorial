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
  miniblue:
    image: ghcr.io/lonegunmanb/miniblue:sha-a1ad451
    ports:
      - "4566:4566"
      - "4567:4567"
    deploy:
      resources:
        limits:
          memory: 512M
EOF
fi

if [ ! -f main.tf ]; then
cat > main.tf <<'EOTF'
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}

  metadata_host                   = "localhost:4567"
  resource_provider_registrations = "none"

  subscription_id = "00000000-0000-0000-0000-000000000000"
  tenant_id       = "00000000-0000-0000-0000-000000000001"
  client_id       = "miniblue"
  client_secret   = "miniblue"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "部署环境（dev / staging / prod）"
}

variable "app_name" {
  type        = string
  default     = "myapp"
  description = "应用名称"
}

variable "suffix" {
  type        = string
  default     = "lab"
  description = "资源名称后缀，避免命名冲突"
}

locals {
  name_prefix = "${var.app_name}-${var.environment}"
  common_tags = {
    Environment = var.environment
    App         = var.app_name
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_resource_group" "setup" {
  name     = "${local.name_prefix}-setup-${var.suffix}"
  location = "East US"
  tags     = local.common_tags
}

resource "azurerm_resource_group" "deploy" {
  depends_on = [azurerm_resource_group.setup]

  name     = "${local.name_prefix}-deploy-${var.suffix}"
  location = "East US"
  tags     = local.common_tags
}

output "name_prefix" {
  value       = local.name_prefix
  description = "资源名称前缀"
}

output "setup_rg" {
  value       = azurerm_resource_group.setup.name
  description = "setup 阶段的 Resource Group 名称"
}

output "deploy_rg" {
  value       = azurerm_resource_group.deploy.name
  description = "deploy 阶段的 Resource Group 名称"
}
EOTF
fi

# ── 2. Create local module for terraform get demo ──
mkdir -p /root/workspace/modules/greet
if [ ! -f /root/workspace/modules/greet/main.tf ]; then
cat > /root/workspace/modules/greet/main.tf <<'EOTF'
variable "name" {
  type    = string
  default = "World"
}

output "message" {
  value = "Hello, ${var.name}!"
}
EOTF
fi

# ── 3. Seed unformatted file for fmt demo ──
cat > /root/workspace/unformatted.tf <<'EOF'
# 格式化演示文件 —— 运行 terraform fmt 来修复此文件的缩进风格
variable "region" {
type    = string
default =  "East US"
description = "Azure region"
}
locals {
  full_name   =   "app-${var.region}"
  is_prod =var.region == "East US" ? true : false
}
EOF

# ── 4. Seed lock-demo workspace for force-unlock demo ──
# Uses local backend + a long-running null_resource provisioner so we can
# script "kill -9" to leave an orphan lock for force-unlock to clean up.
mkdir -p /root/workspace/lock-demo
cat > /root/workspace/lock-demo/main.tf <<'EOTF'
terraform {
  required_version = ">= 1.0"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# 故意放一个会阻塞 60 秒的 provisioner，给我们时间在另一个进程里
# kill -9 模拟崩溃，留下孤儿锁。
resource "null_resource" "slow" {
  triggers = {
    run_id = "force-unlock-demo"
  }

  provisioner "local-exec" {
    command = "sleep 60"
  }
}
EOTF

# ── 5. Install tools, start services, init workspaces ──
install_terraform
apt-get update -qq && apt-get install -y -qq jq > /dev/null 2>&1
start_miniblue
install_azlocal

# Init lock-demo (local backend, null provider — quick).
cd /root/workspace/lock-demo
terraform init

# Init main workspace (azurerm provider, local backend).
# Do NOT apply — students focus on fmt/console/get/graph here, not on cloud
# resources. Pre-init keeps the workspace ready for `terraform fmt -check`,
# `terraform get`, `terraform graph` etc. without an extra wait.
cd /root/workspace
export SSL_CERT_FILE=/root/.miniblue/cert.pem
terraform init

install_theia_plugin
finish_setup
