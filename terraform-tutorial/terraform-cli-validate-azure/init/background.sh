#!/bin/bash
exec > /tmp/background.log 2>&1
set -x

source /root/setup-common.sh

# ── 1. Seed workspace files (assets are copied by Killercoda; these are fallbacks) ──
mkdir -p /root/workspace
cd /root/workspace

if [ ! -f docker-compose.yml ]; then
cat > docker-compose.yml <<'EOF'
services:
  miniblue:
    image: ghcr.io/lonegunmanb/miniblue:sha-3fa70c3
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

  # miniblue HTTPS metadata endpoint
  metadata_host                   = "localhost:4567"
  resource_provider_registrations = "none"

  # miniblue 接受任意凭据
  subscription_id = "00000000-0000-0000-0000-000000000000"
  tenant_id       = "00000000-0000-0000-0000-000000000001"
  client_id       = "miniblue"
  client_secret   = "miniblue"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "部署环境"
}

variable "app_name" {
  type        = string
  default     = "myapp"
  description = "应用名称"
}

variable "suffix" {
  type        = string
  default     = "lab"
  description = "资源名称后缀，用于避免命名冲突"
}

resource "azurerm_resource_group" "main" {
  name     = "${var.app_name}-${var.environment}-rg-${var.suffix}"
  location = "East US"
  tags = {
    Environment = var.environment
    App         = var.app_name
    ManagedBy   = "Terraform"
  }
}

output "resource_group" {
  value = azurerm_resource_group.main.name
}
EOTF
fi

if [ ! -f ci-validate.sh ]; then
cat > ci-validate.sh <<'EOSH'
#!/bin/bash
set -euo pipefail

echo "=== Step 1: terraform init ==="
terraform init -backend=false -input=false > /dev/null 2>&1

echo "=== Step 2: terraform fmt -check ==="
if ! terraform fmt -check -recursive > /dev/null 2>&1; then
  echo "FAIL: 代码格式不符合规范，请运行 terraform fmt"
  exit 1
fi
echo "PASS: 格式检查通过"

echo "=== Step 3: terraform validate ==="
RESULT=$(terraform validate -json || true)
VALID=$(echo "$RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['valid'])")
ERRORS=$(echo "$RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['error_count'])")
WARNINGS=$(echo "$RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['warning_count'])")

if [ "$VALID" = "True" ]; then
  echo "PASS: 验证通过 (warnings: $WARNINGS)"
else
  echo "FAIL: 验证失败 (errors: $ERRORS, warnings: $WARNINGS)"
  echo "$RESULT" | python3 -m json.tool
  exit 1
fi
EOSH
chmod +x ci-validate.sh
fi

# ── 2. Install tooling ──
install_terraform
apt-get update -qq && apt-get install -y -qq jq > /dev/null 2>&1
start_miniblue
install_azlocal

# ── 3. Initialize only (azurerm provider downloaded, no apply — validate
#       does not need any actual Azure resources) ──
export SSL_CERT_FILE=/root/.miniblue/cert.pem
terraform init

install_theia_plugin
finish_setup
