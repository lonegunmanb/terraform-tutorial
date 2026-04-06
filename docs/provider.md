---
order: 5
title: Provider 配置
---

# Provider 配置

Terraform 依赖名为 **Provider** 的插件来与各种云平台、SaaS 服务和其他 API 交互。Provider 是 Terraform 与外部世界之间的桥梁——没有 Provider，Terraform 无法管理任何基础设施。

本章介绍 Provider 的核心概念和配置方法：

## 目录

- [什么是 Provider](#什么是-provider) — Provider 的作用与来源
- [声明 Provider 依赖 (required_providers)](#声明-provider-依赖-required-providers) — 必须告诉 Terraform 去哪里找 Provider
- [配置 Provider](#配置-provider) — 设置区域、认证等运行参数
- [多 Provider 实例 (alias)](#多-provider-实例-alias) — 同一 Provider 的多套配置

---

## 什么是 Provider

每个 Provider 为 Terraform 提供一组**资源类型**（Resource Types）和**数据源**（Data Sources）。例如：

- `hashicorp/aws` Provider 提供 `aws_instance`、`aws_s3_bucket` 等资源
- `hashicorp/google` Provider 提供 `google_compute_instance`、`google_storage_bucket` 等资源
- `hashicorp/azurerm` Provider 提供 `azurerm_virtual_machine`、`azurerm_storage_account` 等资源

Provider 与 Terraform 本体是**分开发布**的——它们有独立的版本号和发布节奏。[Terraform Registry](https://registry.terraform.io/browse/providers) 是公共 Provider 的主要发布渠道。

### Provider 名称与源地址

每个 Provider 有两个标识符：

- **源地址**（Source Address）— Provider 的全球唯一标识
- **本地名称**（Local Name）— 在当前模块中使用的别名

源地址由三部分组成：

```
[hostname/]namespace/type
```

- **hostname**（可选）— 分发 Provider 的注册表地址，默认为 `registry.terraform.io`
- **namespace** — 发布组织，如 `hashicorp`、`aliyun`、`datadog`，默认为 `hashicorp`
- **type** — Provider 管理的平台简称

例如：

| 源地址 | 完全限定地址 | 说明 |
|--------|-------------|------|
| `hashicorp/aws` | `registry.terraform.io/hashicorp/aws` | AWS Provider |
| `Azure/azapi` | `registry.terraform.io/Azure/azapi` | Azure API Provider |
| `datadog/datadog` | `registry.terraform.io/datadog/datadog` | Datadog 监控 Provider |
| `random`        | `registry.terraform.io/hashicorp/random` | Random Provider |

::: info 资源类型与 Provider 的映射
Terraform 通过资源类型名的**第一个单词**（下划线前的部分）来推断它属于哪个 Provider。例如：

- `aws_s3_bucket` → 寻找本地名称为 `aws` 的 Provider
- `google_compute_instance` → 寻找本地名称为 `google` 的 Provider
- `azapi_resource` → 寻找本地名称为 `azapi` 的 Provider

如果没有在 `required_providers` 中声明，Terraform 默认去 `hashicorp` 命名空间下查找——这对 `hashicorp/*` Provider 有效，但对其他命名空间的 Provider 会**失败**。
:::

---

## 声明 Provider 依赖 (required_providers)

每个 Terraform 模块都应该在 `terraform` 块的 `required_providers` 中声明它所依赖的 Provider：

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

`required_providers` 块中的每个参数声明一个 Provider：

- **键**（如 `aws`）— Provider 的本地名称
- **`source`**（推荐）— Provider 的源地址
- **`version`**（推荐）— 版本约束

### 为什么必须声明？

如果你不声明 `required_providers`，Terraform 只能根据资源类型名的前缀推断 Provider，然后去 `hashicorp` 默认命名空间查找。这意味着：

- **`hashicorp/*` Provider**（如 `aws`、`google`、`azurerm`）→ 虽然能找到，但没有版本约束，可能安装不兼容的版本
- **非 `hashicorp` 命名空间的 Provider** → **直接失败**，因为 `hashicorp/<name>` 不存在

```hcl
# ❌ 没有 required_providers 的代码
# 当资源类型以 azapi_ 开头时，Terraform 尝试寻找 hashicorp/azapi
resource "azapi_resource" "web" {
  name = "web-server"
  type = "Microsoft.Compute/virtualMachines@2024-07-01"
}
# terraform init 报错：
# Could not retrieve the list of available versions for provider
# hashicorp/azapi: provider registry registry.terraform.io does
# not have a provider named registry.terraform.io/hashicorp/azapi
```

```hcl
# ✅ 正确声明 required_providers
terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
  }
}

resource "azapi_resource" "web" {
  name = "web-server"
  type = "Microsoft.Compute/virtualMachines@2024-07-01"
}
# terraform init 成功！
```

::: tip 最佳实践
即使使用 `hashicorp/*` 命名空间的 Provider（如 AWS），也应该**始终声明 `required_providers`**并指定 `source` 和 `version`：

1. **版本锁定** — 避免意外升级到不兼容的新版本
2. **可读性** — 任何人打开代码就能知道需要哪些 Provider
3. **一致性** — 团队成员和 CI/CD 环境都使用相同版本
:::

### 版本约束

`version` 参数使用版本约束语法：

| 约束语法 | 含义 | 示例 |
|----------|------|------|
| `"5.0.0"` | 精确版本 | 只允许 5.0.0 |
| `">= 5.0"` | 最低版本 | 5.0 及以上 |
| `"~> 5.0"` | 悲观约束 | ≥ 5.0.0, < 6.0.0 |
| `"~> 5.0.4"` | 补丁级约束 | ≥ 5.0.4, < 5.1.0 |
| `">= 5.0, < 6.0"` | 范围约束 | 同 `~> 5.0` |

::: warning 根模块 vs 子模块
- **根模块**应使用指定版本，防止意外升级
- **可复用的子模块**只设最低版本 `~>`，约束上限，防止意外升级
:::

### 依赖锁定文件

第一次运行 `terraform init` 后，Terraform 会生成 `.terraform.lock.hcl` 文件，记录实际安装的 Provider 版本和校验和。这个文件应提交到版本控制系统中，确保所有人使用完全相同的 Provider 版本。

要升级 Provider 版本，修改 `required_providers` 中的版本约束后运行：

```bash
terraform init -upgrade
```

---

## 配置 Provider

通过 `provider` 块配置 Provider 的运行参数（如区域、认证信息等）：

```hcl
provider "aws" {
  region = "us-east-1"
}
```

`provider` 关键字后的标签是 Provider 的**本地名称**，必须与 `required_providers` 中声明的键一致。块体内的参数由 Provider 自身定义——查阅 Provider 文档了解可用参数。

### 配置值的来源

`provider` 块中的参数值可以使用表达式，但**只能引用在 plan 阶段已知的值**（如输入变量、局部值），不能引用资源的计算属性：

```hcl
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

provider "aws" {
  region = var.aws_region   # ✅ 可以引用变量
  # region = aws_ssm_parameter.region.value  # ❌ 不能引用资源属性
}
```

许多 Provider 支持通过**环境变量**配置认证信息，这在 CI/CD 环境中特别有用——避免将凭据写入代码：

```bash
export AWS_REGION=us-east-1
export AWS_ACCESS_KEY_ID=AKIA...
export AWS_SECRET_ACCESS_KEY=...
```

### 空配置

如果 Provider 没有必填参数（或完全通过环境变量配置），可以省略 `provider` 块。Terraform 会自动创建一个空的默认配置：

```hcl
# 以下两种写法等价：

# 显式空配置
provider "random" {}

# 或者完全省略——Terraform 自动创建默认配置
```

::: tip 只在根模块配置
`provider` 块应该**只在根模块**中定义。子模块从父模块继承 Provider 配置，不应自行定义 `provider` 块——这是 Terraform 的强烈建议。
:::

---

## 多 Provider 实例 (alias)

有时需要同一个 Provider 的**多个配置**——例如在两个不同的 AWS 区域创建资源。通过 `alias` 参数实现：

```hcl
# 默认配置（无 alias）
provider "aws" {
  region = "us-east-1"
}

# 别名配置
provider "aws" {
  alias  = "west"
  region = "us-west-2"
}
```

没有 `alias` 的 `provider` 块是**默认配置**。资源默认使用与资源类型前缀匹配的默认 Provider。要使用别名配置，需在资源上指定 `provider` 元参数：

```hcl
# 使用默认 aws Provider（us-east-1）
resource "aws_s3_bucket" "east_bucket" {
  bucket = "my-east-bucket"
}

# 使用别名 aws.west Provider（us-west-2）
resource "aws_s3_bucket" "west_bucket" {
  provider = aws.west
  bucket   = "my-west-bucket"
}
```

### 没有默认配置的情况

如果所有 `provider` 块都使用了 `alias`，Terraform 会创建一个**隐式的空默认配置**。未指定 `provider` 元参数的资源将使用这个空配置——如果 Provider 有必填参数，就会报错：

```hcl
# 两个都有 alias，没有默认配置
provider "aws" {
  alias  = "east"
  region = "us-east-1"
}

provider "aws" {
  alias  = "west"
  region = "us-west-2"
}

# ⚠️ 这个资源没有指定 provider，会使用隐式空配置
# 如果 AWS 没有通过环境变量配置区域，可能不符合预期
resource "aws_s3_bucket" "default_bucket" {
  bucket = "uses-implied-empty-config"
}
```

### 向子模块传递别名 Provider

如果子模块需要接收别名 Provider，必须在子模块的 `required_providers` 中使用 `configuration_aliases` 声明：

```hcl
# 子模块：modules/infra/main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
      configuration_aliases = [aws.west]
    }
  }
}

resource "aws_s3_bucket" "west_data" {
  provider = aws.west
  bucket   = "west-data-bucket"
}
```

调用方通过 `providers` 参数传递：

```hcl
# 根模块：main.tf
module "west_infra" {
  source = "./modules/infra"
  providers = {
    aws.west = aws.west
  }
}
```

---

## 🧪 动手实验

<KillercodaEmbed src="https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-provider" />
