terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
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

# ── Layer 0: Resource Group ──
# 真实 Azure 中，Resource Group 创建后，控制平面（ARM）与 RBAC 需要数秒到数十秒才能在所有
# 区域 / 服务端点完全生效（最终一致性）。如果立即在子资源上设置 role assignment 或 policy，
# 经常会遇到 "PrincipalNotFound" / "ResourceGroupNotFound" 的瞬时错误。
resource "azurerm_resource_group" "app" {
  name     = "depends-demo-rg"
  location = "East US"

  tags = { Name = "depends-demo" }
}

# ── Layer 1: time_sleep 模拟 Azure 控制平面传播延迟 ──
# 参考: https://github.com/hashicorp/terraform-provider-azurerm/issues/12025
# 类似的延迟同样出现在 role assignment / managed identity / private DNS zone link 等场景。
# time_sleep 通过 depends_on 显式依赖 Resource Group，并把 rg_name 暴露在 triggers 中，
# 供下游资源引用（而非直接引用 azurerm_resource_group.app.name）。
# 这样既保证创建时等待传播完成，也保证 destroy 时按依赖逆序销毁。
resource "time_sleep" "azure_propagation" {
  create_duration = "10s"

  depends_on = [azurerm_resource_group.app]

  triggers = {
    rg_name  = azurerm_resource_group.app.name
    location = azurerm_resource_group.app.location
  }
}

# ── Layer 2: DNS Zone（通过 time_sleep 获取已传播的 RG 名）──
# 依赖链：azurerm_resource_group.app -> time_sleep -> azurerm_dns_zone.data
# 销毁时 Terraform 按逆序操作：先删 DNS zone 与 vnet，再删 time_sleep，最后删 RG。
resource "azurerm_dns_zone" "data" {
  name                = "depends-demo-data.local"
  resource_group_name = time_sleep.azure_propagation.triggers["rg_name"]

  tags = { Name = "data-zone" }
}

# ── Layer 2: Virtual Network（同样通过 time_sleep 获取 RG 信息）──
resource "azurerm_virtual_network" "net" {
  name                = "depends-demo-vnet"
  address_space       = ["10.10.0.0/16"]
  location            = time_sleep.azure_propagation.triggers["location"]
  resource_group_name = time_sleep.azure_propagation.triggers["rg_name"]

  tags = { Name = "data-vnet" }
}
