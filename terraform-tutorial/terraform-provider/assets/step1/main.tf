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
