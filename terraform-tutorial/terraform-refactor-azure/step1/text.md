# import — 纳入已有资源

在实际工作中，很多基础设施是在 Terraform 之外创建的——通过 Azure Portal、az CLI 或其他工具。本节将练习使用 import 块将这些已有资源纳入 Terraform 管理。

## 场景

环境初始化时已经通过 `azlocal` 命令在共享 Resource Group `refactor-rg` 下手动创建了若干 Storage Account。先确认它们的存在：

```
cd /root/workspace/step1
azlocal storage account list --resource-group refactor-rg
```

你会看到很多 Storage Account——其中 `legacy` 开头的是通过 azlocal 手动创建的，其余的是后续步骤预创建的。我们关注的是 `legacyappdata` 和 `legacyapplogs` 这两个。它们不在当前目录的 Terraform 状态文件中——Terraform 并不知道它们的存在。

## 确认 Terraform 不知道这些 Storage Account

查看当前状态：

```
terraform state list
```

Terraform 会提示 No state file was found——因为这个目录还从未执行过 apply，根本没有状态文件。Terraform 对这些 Storage Account 一无所知。

## 编写 import 块和 resource 块

打开 main.tf，在文件底部添加以下代码来导入第一个 Storage Account：

```hcl
import {
  to = azurerm_storage_account.app_data
  id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/refactor-rg/providers/Microsoft.Storage/storageAccounts/legacyappdata"
}

resource "azurerm_storage_account" "app_data" {
  name                     = "legacyappdata"
  resource_group_name      = "refactor-rg"
  location                 = "eastus"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
```

import 块告诉 Terraform：那段冗长的 ARM 资源 ID 对应的 Storage Account `legacyappdata` 应该对应 `azurerm_storage_account.app_data` 这个资源地址。

> **关于 import id**：Azure 资源使用完整的 ARM ID 作为 import id，格式为 `/subscriptions/{subId}/resourceGroups/{rg}/providers/{provider}/{type}/{name}`。这与 AWS 用 bucket 名做 id 不同——但是 import 块的用法完全一致。

## 执行计划

```
terraform plan
```

注意观察输出——你应该看到的是 import 操作，而不是 create：

```
Plan: 1 to import, 0 to add, 0 to change, 0 to destroy.
```

这说明 Terraform 不会重新创建这个 Storage Account，而是将已有的资源纳入管理。

## 执行导入

```
terraform apply -auto-approve
```

验证 Storage Account 已进入状态文件：

```
terraform state list
```

现在应该能看到 `azurerm_storage_account.app_data`。

查看状态中记录的详细信息：

```
terraform state show azurerm_storage_account.app_data
```

## 练习：导入第二个 Storage Account

请自行在 main.tf 中添加 import 块和 resource 块来导入 `legacyapplogs`。它的 ARM ID 是：

```
/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/refactor-rg/providers/Microsoft.Storage/storageAccounts/legacyapplogs
```

完成后执行：

```
terraform apply -auto-approve
terraform state list
```

确认两个 Storage Account 都已被 Terraform 管理。

## 验证：import 块是一次性的

再次执行 plan：

```
terraform plan
```

输出应该是 No changes——import 块对已存在于状态中的资源不会重复执行。

## 使用 for_each 批量导入

两个资源手动写两组 import + resource 还可以接受。但如果有更多呢？

环境中还有三个手动创建的服务 Storage Account，先确认：

```
azlocal storage account list --resource-group refactor-rg | grep legacysvc
```

你应该看到 `legacysvcorders`、`legacysvcpayments` 和 `legacysvcnotif` 三个。

用 for_each 可以一次性导入所有同类型的资源。在 main.tf 底部添加：

```hcl
locals {
  service_accounts = {
    orders        = "legacysvcorders"
    payments      = "legacysvcpayments"
    notifications = "legacysvcnotif"
  }
}

import {
  for_each = local.service_accounts
  to       = azurerm_storage_account.services[each.key]
  id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/refactor-rg/providers/Microsoft.Storage/storageAccounts/${each.value}"
}

resource "azurerm_storage_account" "services" {
  for_each = local.service_accounts

  name                     = each.value
  resource_group_name      = "refactor-rg"
  location                 = "eastus"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
```

关键点：import 块也支持 for_each——它会遍历 map，为每个元素执行一次导入。to 地址中的 `each.key` 对应 map 的键（orders、payments、notifications），id 中的 `each.value` 用来拼出对应的 ARM 资源 ID。

## 执行批量导入

```
terraform plan
```

你应该看到三个 import 操作：

```
Plan: 3 to import, 0 to add, 0 to change, 0 to destroy.
```

执行：

```
terraform apply -auto-approve
```

验证所有五个资源都已纳入管理：

```
terraform state list
```

你应该看到五个资源：两个单独导入的（app_data、app_logs），三个通过 for_each 批量导入的（services["orders"]、services["payments"]、services["notifications"]）。

> 提示：import 块只能写在根模块中。如果需要导入到子模块中的资源，可以在 to 地址中使用 `module.xxx.resource_type.name` 的形式。
