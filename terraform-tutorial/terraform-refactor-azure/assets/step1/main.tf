terraform {
  required_version = ">= 1.5"
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

# ── 练习：使用 import 块将已有的 Storage Account 纳入 Terraform 管理 ──
# 环境中已经通过 azlocal 在 refactor-rg 资源组下手动创建了以下 Storage Account：
#   - legacyappdata
#   - legacyapplogs
#   - legacysvcorders
#   - legacysvcpayments
#   - legacysvcnotif
#
# 请在下方添加 resource 块和 import 块来导入它们。
