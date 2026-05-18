# moved — 重命名资源

当你需要给资源起一个更好的名字时，直接修改名称会导致 Terraform 销毁旧资源、创建新资源。moved 块可以告诉 Terraform "这只是改名，不要删除重建"。

## 场景

进入 step3 目录，这里有两个命名不佳的 Storage Account（b1 和 b2）：

```
cd /root/workspace/step3
terraform state list
```

你应该看到 `azurerm_storage_account.b1` 和 `azurerm_storage_account.b2`。

看看它们对应的实际 Storage Account 名：

```
terraform state show azurerm_storage_account.b1 | grep -E '^\s*name '
terraform state show azurerm_storage_account.b2 | grep -E '^\s*name '
```

b1 是 `mvdemouploads`，b2 是 `mvdemoarchives`。Terraform 里的地址 b1、b2 毫无含义，我们要重构为更清晰的名称。

## 先看看直接改名会怎样

假设我们直接把 b1 改成 uploads——临时修改看 plan（不要 apply）：

```
sed -i 's/"b1"/"uploads"/' main.tf
terraform plan
```

Terraform 会显示一个 destroy（b1）加一个 create（uploads）——这意味着 Storage Account 会被删除再重建！对于生产环境的存储账号来说，这是灾难（数据会全部消失）。

恢复原始文件：

```
sed -i 's/"uploads"/"b1"/' main.tf
```

## 使用 moved 块安全重命名

编辑 main.tf，同时修改资源名称并添加 moved 块：

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

resource "azurerm_storage_account" "uploads" {
  name                     = "mvdemouploads"
  resource_group_name      = "refactor-rg"
  location                 = "eastus"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_account" "archives" {
  name                     = "mvdemoarchives"
  resource_group_name      = "refactor-rg"
  location                 = "eastus"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

moved {
  from = azurerm_storage_account.b1
  to   = azurerm_storage_account.uploads
}

moved {
  from = azurerm_storage_account.b2
  to   = azurerm_storage_account.archives
}
EOF
```

## 查看计划

```
terraform plan
```

这次输出完全不同——没有 destroy，没有 create：

```
# azurerm_storage_account.b1 has moved to azurerm_storage_account.uploads
# azurerm_storage_account.b2 has moved to azurerm_storage_account.archives
```

Terraform 理解了：这只是换了 Terraform 内部的"身份证号"，同一个 Storage Account。

## 执行

```
terraform apply -auto-approve
```

## 验证

检查状态文件中的新地址：

```
terraform state list
```

资源地址已经变成 `azurerm_storage_account.uploads` 和 `azurerm_storage_account.archives`。

确认 Storage Account 完全没变：

```
azlocal storage account list --resource-group refactor-rg | grep mvdemo
```

名字和数据完全一致——只是 Terraform 里的"身份证号"更新了。

再跑一次 plan 确认干净：

```
terraform plan
```

输出应该是 No changes。

> 提示：moved 块对资源的所有实例生效——如果资源使用了 count 或 for_each，所有实例会自动跟随移动。同样地，重命名模块调用也可以用 moved 块实现，例如 `from = module.old_name, to = module.new_name`。
