# 第一步：理解 plan 输出

## 无变更时的输出

环境已预先 apply，进入工作目录先确认四个资源都在：

```
cd /root/workspace
azlocal group list
azlocal dns zone list --resource-group myapp-dev-rg-lab
azlocal network vnet list --resource-group myapp-dev-rg-lab
```

`azlocal` 走 HTTP 4566，无需证书；它是 miniblue 自带的 CLI，用法类似 `awslocal`。

此时配置与 state 完全一致，运行 plan 应显示无变更：

```
terraform plan
```

注意末尾的汇总行：

```
No changes. Your infrastructure matches the configuration.
```

## 触发修改（update）：观察 ~ 符号

向 `local.common_tags` 中增加一个新标签，四个资源都共用这个 locals，所以它们都会被标记为变更：

```
sed -i 's/ManagedBy   = "Terraform"/ManagedBy   = "Terraform"\n    Owner       = "platform-team"/' main.tf
```

再次运行 plan，这次会看到变更：

```
terraform plan
```

四个资源行首均显示 ~ 符号，表示将被原地修改（update in place）。

仔细阅读属性变更行：

- 带 + 的行是新增属性
- 带 - 的行是移除属性
- 带 ~ 的行是值发生变化的属性
- (known after apply) 表示该值只有在实际 apply 后才能确定

末尾的汇总行会显示：

```
Plan: 0 to add, 4 to change, 0 to destroy.
```

## 触发重建（replace）：观察 -/+ 与 +/- 符号

DNS Zone 的 `name` 是不可变属性，修改它会触发先销毁再重建（replace）。先看看直接改名会发生什么：

```
sed -i 's/name                = "${var.app_name}-${var.environment}-logs-${var.suffix}.local"/name                = "${var.app_name}-${var.environment}-logs2-${var.suffix}.local"/' main.tf
terraform plan
```

在 azurerm_dns_zone.logs 资源行前，你会看到 -/+ 符号，以及 forces replacement 的提示：

```
-/+ resource "azurerm_dns_zone" "logs" {
```

这是默认的重建顺序：先销毁旧资源，再创建新资源。

现在为 app DNS Zone 加上 `create_before_destroy = true`，再观察符号的差异：

```
sed -i '/resource "azurerm_dns_zone" "app"/a\  lifecycle {\n    create_before_destroy = true\n  }' main.tf
terraform plan -replace=azurerm_dns_zone.app
```

app DNS Zone 行前显示的是 +/- 符号：

```
+/- resource "azurerm_dns_zone" "app" {
```

plan 输出开头的图例也会同时显示两种符号的含义：

```
-/+ destroy and then create replacement
+/- create replacement and then destroy
```

关键区别：

- -/+ 先销毁后创建，中间有短暂停机窗口
- +/- 先创建后销毁，新资源就绪后才移除旧资源（零停机替换）

汇总行变为：

```
Plan: 2 to add, 0 to change, 2 to destroy.
```

::: tip
Azure 资源 ID 由资源路径（subscription / resourceGroup / 资源类型 / 名称）唯一决定，主键未变时重建前后的 ID 相同——这一点和 AWS（ARN 中常含随机后缀）不同。判断重建是否发生应以 plan 的 `-/+` / `+/-` 符号与汇总行为准，而不是对比 ID。
:::

## 恢复配置

将 main.tf 恢复为原始状态，后续步骤继续使用。最简单的方式是直接覆写文件：

```
cat > /root/workspace/main.tf <<'EOTF'
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

variable "environment" {
  type    = string
  default = "dev"
}

variable "app_name" {
  type    = string
  default = "myapp"
}

variable "suffix" {
  type    = string
  default = "lab"
}

locals {
  common_tags = {
    Environment = var.environment
    App         = var.app_name
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_resource_group" "main" {
  name     = "${var.app_name}-${var.environment}-rg-${var.suffix}"
  location = "East US"
  tags     = local.common_tags
}

resource "azurerm_dns_zone" "app" {
  name                = "${var.app_name}-${var.environment}-app-${var.suffix}.local"
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

resource "azurerm_dns_zone" "logs" {
  name                = "${var.app_name}-${var.environment}-logs-${var.suffix}.local"
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

resource "azurerm_virtual_network" "net" {
  name                = "${var.app_name}-${var.environment}-vnet-${var.suffix}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

output "resource_group" {
  value = azurerm_resource_group.main.name
}

output "app_dns_zone" {
  value = azurerm_dns_zone.app.name
}

output "logs_dns_zone" {
  value = azurerm_dns_zone.logs.name
}

output "vnet" {
  value = azurerm_virtual_network.net.name
}
EOTF
terraform plan
```

确认末尾显示 No changes 后进入下一步。
