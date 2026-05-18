# moved — 提取到模块

随着代码规模增长，你可能需要将根模块中零散的资源提取到子模块中。moved 块可以让这种重构安全进行——不销毁任何资源。

## 场景

进入 step4 目录，查看当前状态：

```
cd /root/workspace/step4
terraform state list
```

你应该看到两个资源直接位于根模块中：`azurerm_storage_account.user_uploads` 和 `azurerm_storage_account.user_backups`。

确认 Storage Account 存在：

```
azlocal storage account list --resource-group refactor-rg | grep moduser
```

## 目标

我们要把这两个资源提取到 `modules/storage-account` 子模块中。目标架构：

```
根模块
├── module "uploads"  → modules/storage-account  (管理 moduseruploads)
└── module "backups"  → modules/storage-account  (管理 moduserbackups)
```

`modules/storage-account` 子模块已经准备好了，先看一下它的接口：

```
cat /root/workspace/modules/storage-account/variables.tf
cat /root/workspace/modules/storage-account/outputs.tf
```

## 重构代码

编辑 main.tf，将两个 resource 块替换为 module 调用，并添加 moved 块告诉 Terraform 资源的新地址：

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

module "uploads" {
  source              = "../modules/storage-account"
  name                = "moduseruploads"
  resource_group_name = "refactor-rg"
  location            = "eastus"
  tags = {
    Purpose = "uploads"
  }
}

module "backups" {
  source              = "../modules/storage-account"
  name                = "moduserbackups"
  resource_group_name = "refactor-rg"
  location            = "eastus"
  tags = {
    Purpose = "backups"
  }
}

moved {
  from = azurerm_storage_account.user_uploads
  to   = module.uploads.azurerm_storage_account.this
}

moved {
  from = azurerm_storage_account.user_backups
  to   = module.backups.azurerm_storage_account.this
}
EOF
```

注意 moved 块中的 to 地址是 `module.uploads.azurerm_storage_account.this`——因为子模块内部的资源名称是 `this`（查看 `modules/storage-account/main.tf` 就能确认），所以完整路径是 `module.<调用名>.azurerm_storage_account.this`。

## 重新初始化

因为添加了新的 module 调用，需要重新 init：

```
terraform init
```

## 查看计划

```
terraform plan
```

你应该看到两条移动记录，没有任何销毁或创建：

```
# azurerm_storage_account.user_uploads has moved to module.uploads.azurerm_storage_account.this
# azurerm_storage_account.user_backups has moved to module.backups.azurerm_storage_account.this
```

## 执行

```
terraform apply -auto-approve
```

## 验证

检查新的资源地址：

```
terraform state list
```

资源地址已经变成 `module.uploads.azurerm_storage_account.this` 和 `module.backups.azurerm_storage_account.this`。

确认 Storage Account 完全没有变化：

```
azlocal storage account list --resource-group refactor-rg | grep moduser
```

Storage Account 还是原来的，数据未受影响。

最后确认 plan 干净：

```
terraform plan
```

No changes——重构完成，零停机、零风险。

> 小结：moved 块让你可以自由地重组代码结构——重命名、提取模块、拆分模块——而不必担心 Terraform 误删真实的基础设施。记住：移除 moved 块是破坏性变更，对于公开模块建议永久保留。
