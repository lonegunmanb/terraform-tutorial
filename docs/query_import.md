---
order: 15
title: 批量导入资源
---

# terraform query：批量查询与导入已有资源

在[代码重构](/refactor_module)一章中，我们介绍了 `import` 块的基本用法和 `for_each` 批量导入模式。但那种方式需要**事先知道**每个资源的 ID，并手动维护一个 ID 映射表——当需要导入几十甚至上百个资源时，这非常繁琐。

自 Terraform v1.12 起，`terraform query` 命令和 `.tfquery.hcl` 配置文件提供了一种全新的工作流：**先查询已有基础设施中的资源，再自动生成 `import` + `resource` 块**，实现真正的批量导入。

## 完整工作流

批量查询导入分为四个步骤：

```
1. 编写查询 (.tfquery.hcl)
       ↓
2. terraform query  →  查看发现的资源列表
       ↓
3. terraform query -generate-config-out=generated.tf
       ↓  → 自动生成 import + resource 块
4. 将生成的配置合并到主配置 → terraform apply → 导入完成
```

## .tfquery.hcl 文件与 list 块

查询配置使用 `.tfquery.hcl` 扩展名，核心构建块是 `list`。每个 `list` 块定义一次资源查询：

```hcl
# discover.tfquery.hcl

list "aws_s3_bucket" "all_buckets" {
  provider = aws
}
```

`list` 块的第一个标签是**资源类型**，第二个标签是**查询名称**（在当前目录中唯一）。

### list 块属性

| 属性 | 说明 | 默认值 |
|------|------|--------|
| `provider` | 使用哪个 Provider 配置执行查询（必填） | — |
| `config` | Provider 特定的过滤条件 | — |
| `limit` | 返回结果的最大数量 | `100` |
| `include_resource` | 是否返回完整的资源属性（而非仅标识） | `false` |
| `count` | 创建多个查询实例（与 `for_each` 互斥） | — |
| `for_each` | 基于集合创建多个查询实例（与 `count` 互斥） | — |

### 使用 config 过滤

`config` 块中的参数是 **Provider 特定的**，用于缩小查询范围。以 AWS 为例：

```hcl
list "aws_instance" "prod_servers" {
  provider = aws
  limit    = 50

  config {
    filter {
      name   = "tag:Environment"
      values = ["prod"]
    }
    filter {
      name   = "instance-state-name"
      values = ["running"]
    }
  }
}
```

不同 Provider 支持的 `config` 参数各不相同，需要查阅对应的 Provider 文档。

### 使用 for_each 多维查询

在[代码重构](/refactor_module#批量导入)中我们介绍过 `import` 块的 `for_each`，`list` 块同样支持 `for_each` 和 `count`。例如，用 `count` 创建多个查询实例：

```hcl
variable "subnet_ids" {
  type = list(string)
}

list "aws_instance" "server" {
  provider = aws
  count    = length(var.subnet_ids)
}
```

也可以用 `for_each` 基于集合创建多个查询：

```hcl
variable "environments" {
  type    = set(string)
  default = ["prod", "staging"]
}

list "aws_s3_bucket" "by_env" {
  for_each = var.environments
  provider = aws
}
```

## terraform query 命令

### 基本查询

```bash
# 执行查询，将结果打印到终端
terraform query

# JSON 格式输出
terraform query -json
```

输出包含每个发现的资源的标识信息，格式为 `list.<类型>.<标签>`。

### 传递变量

如果 `.tfquery.hcl` 中定义了 `variable`，可以通过命令行传入：

```bash
terraform query -var 'env=prod'
terraform query -var-file=query-vars.tfvars
```

### 生成导入配置

这是最核心的功能——自动生成 `import` 和 `resource` 块：

```bash
terraform query -generate-config-out=generated.tf
```

Terraform 会：

1. 执行 `.tfquery.hcl` 中定义的所有查询
2. 对每个发现的资源，生成一个 `import` 块（含资源标识）和一个 `resource` 块（含当前属性）
3. 将所有生成的配置写入 `generated.tf`

::: warning
目标文件不能已存在，否则命令会报错。需要先删除旧文件再重新生成。
:::

### 命令选项

| 选项 | 说明 |
|------|------|
| `-generate-config-out=FILE` | 生成 import + resource 块到指定文件 |
| `-json` | JSON 格式输出 |
| `-var 'KEY=VALUE'` | 设置查询变量 |
| `-var-file=FILE` | 从文件加载变量 |
| `-no-color` | 禁用颜色输出 |

## 生成的配置结构

`terraform query -generate-config-out` 生成的文件内容类似：

```hcl
# generated.tf

import {
  to = aws_s3_bucket.all_buckets["my-data-bucket"]
  id = "my-data-bucket"
}

resource "aws_s3_bucket" "all_buckets" {
  bucket = "my-data-bucket"
  # ... 其他从远端读取的属性
}

import {
  to = aws_s3_bucket.all_buckets["my-logs-bucket"]
  id = "my-logs-bucket"
}

# ... 更多资源
```

## 导入资源

将生成的配置合并到主配置中（通常需要手动调整）：

1. **检查生成的配置** — 移除只读属性、调整命名、添加变量引用
2. **将 `import` 和 `resource` 块复制到主配置**
3. **执行导入**：

```bash
terraform plan    # 确认显示 "X to import, 0 to add"
terraform apply   # 执行导入
```

4. **清理** — 导入完成后可以删除 `import` 块（或保留作为历史记录）和 `generated.tf`

## 与 import 块 for_each 的关系

在[代码重构](/refactor_module#批量导入)中，我们讲过使用 `import` 块的 `for_each` 手动批量导入：

```hcl
locals {
  buckets = {
    data = "my-data-bucket"
    logs = "my-logs-bucket"
  }
}

import {
  for_each = local.buckets
  to       = aws_s3_bucket.this[each.key]
  id       = each.value
}
```

这种方式需要**你已经知道所有资源的 ID**。`terraform query` 的优势在于：

| 对比 | `import` + `for_each` | `terraform query` |
|------|----------------------|-------------------|
| 前提 | 已知所有资源 ID | 不需要事先知道 |
| 发现能力 | 无 | 自动发现未管理的资源 |
| 配置生成 | 需手动编写 `resource` 块 | 自动生成 |
| 适用规模 | 少量已知资源 | 大量未知资源 |
| 过滤能力 | 手动筛选 | Provider 原生过滤 |
| 版本要求 | Terraform v1.5+ | Terraform v1.12+ |

两者可以结合使用——先用 `terraform query` 发现资源并生成初始配置，然后根据需要重构为 `for_each` 模式管理。

## 参数化查询

`.tfquery.hcl` 文件支持 `variable` 和 `locals` 块，让查询可复用：

```hcl
# discover.tfquery.hcl

variable "environment" {
  type    = string
  default = "prod"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

list "aws_s3_bucket" "env_buckets" {
  provider = aws

  config {
    filter {
      name   = "tag:Environment"
      values = [var.environment]
    }
  }
}
```

```bash
# 查询 prod 环境
terraform query -var 'environment=prod'

# 查询 staging 环境
terraform query -var 'environment=staging'
```

## 最佳实践

::: tip 建议的工作流
1. 先用 `terraform query`（不带 `-generate-config-out`）预览发现的资源数量和类型
2. 调整 `config` 过滤条件和 `limit`，确保查询范围合理
3. 使用 `-generate-config-out` 生成配置
4. **仔细审查**生成的配置——移除不需要的资源、调整属性、统一命名
5. 合并到主配置后先 `terraform plan`，确认只有 import 操作
6. 执行 `terraform apply` 完成导入
:::

::: warning 注意事项
- `terraform query` 需要 Provider 支持查询功能，并非所有资源类型都可查询
- `include_resource = true` 会返回完整属性，可能影响大批量查询的性能
- 生成的配置可能包含只读属性或由 Provider 计算的值，需要手动清理
- 导入操作不会影响实际基础设施——只是将状态信息写入 Terraform 状态文件
:::

---

## 动手实验

<KillercodaEmbed src="https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-query-import" />
