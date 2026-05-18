# removed — 移除托管资源

有时候我们需要让 Terraform 停止管理某个资源，但不希望销毁实际的基础设施。removed 块正是为此设计的。

## 场景

进入 step2 目录，这里的配置已经被预先 apply 过，管理着两个 Storage Account：

```
cd /root/workspace/step2
terraform state list
```

你应该能看到 `azurerm_storage_account.app_data` 和 `azurerm_storage_account.app_logs`。

用 `azlocal` 确认这两个 Storage Account 在 miniblue 中真实存在：

```
azlocal storage account list --resource-group refactor-rg | grep refapp
```

## 如果直接删除 resource 块会怎样？

假设我们想停止管理 `app_logs`。先看看如果粗暴地删除 resource 块会发生什么——不要真的 apply，只是看 plan。

写一个不包含 `app_logs` 的配置：

```
cat > main.tf << 'DELETED'
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

resource "azurerm_storage_account" "app_data" {
  name                     = "refappdata"
  resource_group_name      = "refactor-rg"
  location                 = "eastus"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
DELETED
```

查看计划：

```
terraform plan
```

Terraform 会提示要**销毁** `app_logs`！这不是我们想要的。

恢复原始文件：

```
cat > main.tf << 'RESTORE'
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

resource "azurerm_storage_account" "app_data" {
  name                     = "refappdata"
  resource_group_name      = "refactor-rg"
  location                 = "eastus"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_account" "app_logs" {
  name                     = "refapplogs"
  resource_group_name      = "refactor-rg"
  location                 = "eastus"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
RESTORE
```

## 使用 removed 块

正确的做法是用 removed 块替换 resource 块。编辑 main.tf，将 `app_logs` 的 resource 块替换为 removed 块：

```
cat > main.tf << 'EOF'
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

resource "azurerm_storage_account" "app_data" {
  name                     = "refappdata"
  resource_group_name      = "refactor-rg"
  location                 = "eastus"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

removed {
  from = azurerm_storage_account.app_logs

  lifecycle {
    destroy = false
  }
}
EOF
```

## 查看计划

```
terraform plan
```

注意这次的输出完全不同——Terraform 会显示：

```
# azurerm_storage_account.app_logs will no longer be managed by Terraform,
# but will not be destroyed
# (destroy = false is set in the configuration)
```

没有销毁操作！

## 执行

```
terraform apply -auto-approve
```

## 验证

确认状态中只剩一个资源：

```
terraform state list
```

只有 `azurerm_storage_account.app_data` 了。

但 `refapplogs` 在 miniblue 中依然存在：

```
azlocal storage account list --resource-group refactor-rg | grep refapp
```

`refapplogs` 还在——Terraform 只是不再管理它了，没有销毁。

这就是 removed 块的价值：声明式地告知 Terraform "这个资源我不管了，但别删它"。

> 提示：与 import 不同，removed 块可以在任意模块中使用——模块维护者可以在子模块中用 removed 块移除资源，调用方升级模块版本时自动生效。
