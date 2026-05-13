# 第一步：terraform import 命令

## 确认已有基础设施

进入工作目录，先用 azlocal 确认环境中已有若干 Resource Group（这些是通过 miniblue ARM API 直接创建的，不在 Terraform 管理中）：

```
cd /root/workspace
azlocal group list
```

可以看到 legacy-rg、app-dev-rg、app-staging-rg 等资源组。查看 legacy-rg 的标签：

```
azlocal group show --name legacy-rg
```

输出中应当能看到 location 为 eastus，tags 为 Environment=production、Team=backend。

此时 Terraform 状态为空（从未执行过 apply）：

```
terraform show
```

输出为空——Terraform 还不知道这些资源的存在。

## 声明资源块

要导入 legacy-rg 资源组，首先需要在配置中声明对应的 resource 块。先写一个最小的空块：

```
cat >> main.tf <<'EOF'

resource "azurerm_resource_group" "app" {
}
EOF
```

## 执行导入

azurerm 资源使用完整的 Azure Resource ID 作为 import 的 ID。Resource Group 的 ID 格式为：

```
/subscriptions/{sub}/resourceGroups/{name}
```

本课程中 subscription_id 是 00000000-0000-0000-0000-000000000000，所以执行：

```
terraform import azurerm_resource_group.app /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/legacy-rg
```

Terraform 通过 azurerm provider 查询了远端资源的实际属性，并记录到状态中。确认资源已在状态中：

```
terraform state list
```

查看导入后的资源详情：

```
terraform state show azurerm_resource_group.app
```

输出会显示 name、location 与 tags 全部完整。

## 补全配置

现在运行 plan 看看配置与状态的差异：

```
terraform plan
```

plan 报错——因为 azurerm_resource_group 的 name 与 location 是必填参数，而我们的 resource 块是空的。根据 state show 的输出补全配置：

```
cat > main.tf <<'EOF'
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

resource "azurerm_resource_group" "app" {
  name     = "legacy-rg"
  location = "eastus"
  tags = {
    Environment = "production"
    Team        = "backend"
  }
}
EOF
```

再次运行 plan 验证：

```
terraform plan
```

如果显示 No changes 或仅有 Terraform 无法控制的只读属性差异，说明配置已与实际状态对齐。

## 验证 Terraform 已接管

现在可以通过 Terraform 修改这个 Resource Group。例如添加一个新标签：

```
sed -i 's/Team        = "backend"/Team        = "backend"\n    ManagedBy   = "Terraform"/' main.tf
terraform apply -auto-approve
```

通过 azlocal 验证标签已更新：

```
azlocal group show --name legacy-rg
```

输出中应当能看到新增的 ManagedBy=Terraform 标签。Terraform 已完全接管了这个资源组的管理。

进入下一步学习导入到 for_each 资源。
