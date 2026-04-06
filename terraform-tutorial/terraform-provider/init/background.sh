#!/bin/bash
exec > /tmp/background.log 2>&1
set -x

source /root/setup-common.sh

# ── 1. Ensure workspace directories exist ──
mkdir -p /root/workspace/step1
mkdir -p /root/workspace/step2/tests

# ── 2. Seed workspace files (fallback if assets copy fails) ──

if [ ! -f /root/workspace/step1/main.tf ]; then
cat > /root/workspace/step1/main.tf <<'EOTF'
# 这段代码从网上复制而来，直接使用了 Azure API Provider
# 但缺少必要的 terraform 块和 required_providers 声明
#
# 请先运行 terraform init 观察会发生什么

provider "azapi" {
}

resource "azapi_resource" "rg" {
  type     = "Microsoft.Resources/resourceGroups@2024-03-01"
  name     = "example-rg"
  location = "eastus"
}

resource "azapi_resource" "vnet" {
  type      = "Microsoft.Network/virtualNetworks@2024-01-01"
  name      = "example-vnet"
  parent_id = azapi_resource.rg.id
  location  = "eastus"

  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["10.0.0.0/16"]
      }
    }
  }
}
EOTF
fi

if [ ! -f /root/workspace/step2/exercises.tf ]; then
cat > /root/workspace/step2/exercises.tf <<'EOTF'
# =============================================
# 🧪 Provider 配置练习
# =============================================
# 完成以下三道练习，然后运行 terraform test 验证答案。
#
# 运行命令：
#   terraform test
#
# 所有测试通过即为完成！
# =============================================


# ── 练习 1：AWS Provider 的源地址 ──
# AWS Provider 由 HashiCorp 官方维护并发布在 Terraform Registry 上。
# 请写出它的源地址（格式：namespace/type）
#
# 提示：格式类似 "某组织/某平台"

locals {
  # TODO: 将 "____" 替换为正确的源地址
  aws_provider_source = "____"
}


# ── 练习 2：资源类型与 Provider 的关系 ──
# 如果你在代码中看到一个资源类型是 google_compute_instance
# Terraform 会默认去寻找哪个 Provider 的本地名称？
#
# 提示：Terraform 取资源类型名下划线前的第一个单词

locals {
  # TODO: 将 "____" 替换为 Provider 的本地名称
  google_provider_local_name = "____"
}


# ── 练习 3：完全限定的源地址 ──
# 当你在 required_providers 中写 source = "hashicorp/aws" 时，
# Terraform 内部实际使用的完全限定源地址是什么？
#
# 提示：省略 hostname 时，Terraform 默认补全 registry.terraform.io

locals {
  # TODO: 将 "____" 替换为完全限定的源地址
  aws_full_source = "____"
}
EOTF
fi

if [ ! -f /root/workspace/step2/outputs.tf ]; then
cat > /root/workspace/step2/outputs.tf <<'EOTF'
# 此文件用于测试验证，请勿修改

output "check_aws_source" {
  value = local.aws_provider_source
}

output "check_google_local_name" {
  value = local.google_provider_local_name
}

output "check_aws_full_source" {
  value = local.aws_full_source
}
EOTF
fi

if [ ! -f /root/workspace/step2/tests/exercises.tftest.hcl ]; then
cat > /root/workspace/step2/tests/exercises.tftest.hcl <<'EOTF'
run "check_answers" {

  assert {
    condition     = output.check_aws_source == "hashicorp/aws"
    error_message = "练习 1 错误：AWS Provider 的源地址应为 \"hashicorp/aws\"（namespace 是 hashicorp，type 是 aws）"
  }

  assert {
    condition     = output.check_google_local_name == "google"
    error_message = "练习 2 错误：google_compute_instance 对应的 Provider 本地名称应为 \"google\"（取下划线前的第一个单词）"
  }

  assert {
    condition     = output.check_aws_full_source == "registry.terraform.io/hashicorp/aws"
    error_message = "练习 3 错误：完全限定地址应为 \"registry.terraform.io/hashicorp/aws\"（补全默认的 hostname）"
  }

}
EOTF
fi

# ── 3. Install tools ──
install_terraform

finish_setup
