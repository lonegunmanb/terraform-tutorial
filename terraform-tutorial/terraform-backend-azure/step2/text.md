# 第二步：配置 azurerm 后端

在上一步中，我们用本地后端创建了 Storage Account `tfstatelab` 与 Blob Container `tfstate`。现在我们将状态迁移到这个 container 中，并亲手体验**基于 blob lease 的状态锁定**。

## azurerm 后端 vs S3 后端

| 维度 | S3 后端 | azurerm 后端 |
|------|---------|-------------|
| 存储位置 | S3 Bucket 中的对象 | Storage Account → Container 中的 Blob |
| 状态锁 | DynamoDB 表（独立资源） | blob lease（作用在状态 blob 本身） |
| 锁的可见性 | DynamoDB Item，可 scan 查询 | blob 的 LeaseState 属性 |
| 锁释放 | 删除 DynamoDB Item | 释放 lease |

azurerm 后端不需要单独的"锁表"——租约机制已经天然实现了互斥。

## 确认当前状态

确认当前 Terraform 使用本地后端管理着资源：

```
cd /root/workspace
terraform state list
```

你应该看到 4 个资源——状态目前存储在本地 terraform.tfstate 文件中。

## 修改配置，添加 azurerm 后端

用以下命令替换 main.tf，添加 azurerm 后端配置（资源定义保持不变，只是在 terraform 块中新增了 backend "azurerm"）：

```
cat > main.tf <<'EOF'
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

  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstatelab"
    container_name       = "tfstate"
    key                  = "demo/terraform.tfstate"

    # 指向 miniblue（HTTPS metadata + ARM 端点 4567）
    metadata_host                   = "localhost:4567"
    resource_provider_registrations = "none"

    # miniblue 接受任意凭据
    subscription_id = "00000000-0000-0000-0000-000000000000"
    tenant_id       = "00000000-0000-0000-0000-000000000001"
    client_id       = "miniblue"
    client_secret   = "miniblue"
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

resource "azurerm_resource_group" "demo" {
  name     = "demo-app-rg"
  location = "East US"
  tags = {
    Name      = "Demo Resource Group"
    ManagedBy = "Terraform"
  }
}

resource "azurerm_resource_group" "state" {
  name     = "tfstate-rg"
  location = "East US"
  tags = {
    Name      = "Terraform State RG"
    ManagedBy = "Terraform"
  }
}

resource "azurerm_storage_account" "state" {
  name                     = "tfstatelab"
  resource_group_name      = azurerm_resource_group.state.name
  location                 = azurerm_resource_group.state.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    Name      = "Terraform State Storage"
    ManagedBy = "Terraform"
  }
}

resource "azurerm_storage_container" "state" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}

output "demo_resource_group" {
  value = azurerm_resource_group.demo.name
}

output "state_storage_account" {
  value = azurerm_storage_account.state.name
}

output "state_container" {
  value = azurerm_storage_container.state.name
}
EOF
```

注意 backend "azurerm" 块中的关键配置：

- resource_group_name / storage_account_name / container_name 三件套定位 Blob Container
- key 指定状态文件在 container 中的 blob 名称
- metadata_host 指向 miniblue 的 HTTPS ARM metadata 端点（与 provider 一致）

## 迁移状态到 azurerm 后端

运行 terraform init，Terraform 会检测到后端配置变更：

```
terraform init
```

当提示 Do you want to copy existing state to the new backend? 时，输入 yes 并回车。Terraform 会将本地 terraform.tfstate 中的状态数据迁移到 Blob Container 中。

## 验证迁移结果

确认 Terraform 仍能正常管理资源：

```
terraform plan
```

输出应显示 No changes——迁移对资源管理没有任何影响。

## 体验 blob lease 状态锁定

状态锁定的作用是：当一个 Terraform 操作正在执行时，其他操作无法同时修改状态，避免冲突和数据损坏。在 azurerm 后端下，这是通过 Azure Blob 的 lease（租约）机制实现的——Terraform 在 apply 开始时为状态 blob 申请一份独占租约，结束时释放。

我们用一个 time_sleep 资源让 terraform apply 阻塞 30 秒，在这段时间内观察锁的存在。先添加 time_sleep 资源：

```
cat >> main.tf <<'EOF'

resource "time_sleep" "lock_demo" {
  create_duration = "30s"
}
EOF
```

环境中预置了一个演示脚本 show-lock.sh，它会自动完成以下操作：

1. 后台启动 terraform apply
2. 等待 Terraform 获取 blob lease
3. 尝试并发执行 terraform plan——你会看到状态锁冲突错误
4. 等待 apply 完成，确认 lease 被自动释放后再次 plan 成功

运行脚本：

```
bash ./show-lock.sh
```

观察输出，你会看到关键信息：

**锁冲突错误** —— 并发 terraform plan 时会报错，类似：

```
Error: Error acquiring the state lock

Lock Info:
  Path:      tfstate/demo/terraform.tfstate
  Operation: OperationTypeApply
```

这正是 blob lease 在保护你——它阻止了并发操作，确保同一时间只有一个 Terraform 进程能修改状态。

**锁自动释放** —— apply 完成后再次 plan 不再报错，说明 Terraform 已经释放了 lease。

## 清理 time_sleep

time_sleep 仅用于演示锁定，现在将它从配置中移除：

```
sed -i '/^resource "time_sleep"/,/^}/d' main.tf
terraform apply -auto-approve
```

确认状态干净：

```
terraform plan
```

输出应显示 No changes。

## 关键点

- azurerm 后端将状态以 blob 的形式存储在 Azure Storage Account 的 Container 中，团队成员可以共享
- 状态 Storage Account/Container 由上一步的 Terraform 代码创建，是普通的 Azure 存储资源
- 状态锁通过 blob lease 实现——无需额外的"锁表"，租约直接作用在状态 blob 上
- Terraform 在执行 apply/destroy 等修改操作时自动获取租约，完成后自动释放
- 持有租约期间，其他 Terraform 操作会立即报错，避免状态被破坏
