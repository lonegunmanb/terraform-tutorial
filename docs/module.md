---
order: 5
title: Terraform 模块
---

# Terraform 模块

Terraform 模块（Module）是 Terraform 配置的逻辑封装单元，是实现代码复用、团队协作和基础设施标准化的核心机制。

本章将系统介绍模块的概念与实践，涵盖以下内容：

## 目录

- [何为 module](#何为-module) — 模块的概念与作用，如何编写模块
- [使用 module](#使用-module) — 调用模块、传参、输出引用、count、for_each、depends_on
- [重构](#重构) — 使用 moved 块安全地重构模块

---

## 何为 module

模块（Module）是 Terraform 中**最核心的代码组织单元**。简单来说，一个包含 `.tf` 文件的目录就是一个模块。

你在前面所有章节中编写的代码——放在 `/root/workspace/step*` 目录下的那些 `.tf` 文件——本身就构成了一个模块，叫做 **根模块**（Root Module）。当你执行 `terraform plan` 或 `terraform apply` 时，Terraform 从当前工作目录加载所有 `.tf` 文件，这个目录就是根模块。

### 根模块（Root Module）

每次执行 Terraform 命令时，当前工作目录就是根模块。根模块是整个配置的入口点。Terraform 的执行总是从根模块开始。

你之前写过的所有代码——provider 配置、resource 声明、variable 和 output 定义——都属于根模块的内容。即使你没有刻意"创建模块"，你其实一直在使用模块：

```
/root/workspace/step1          ← 这就是根模块
  ├── main.tf
  ├── variables.tf
  └── outputs.tf
```

### 子模块（Child Module）

当一个模块通过 `module` 块调用另一个模块时，被调用的模块称为**子模块**（Child Module）。子模块可以来自本地路径、Terraform Registry、Git 仓库等多种来源：

```hcl
# 从本地路径调用子模块
module "network" {
  source = "./modules/network"
  vpc_cidr = "10.0.0.0/16"
}

# 从 Terraform Registry 调用子模块
module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.0.0"
  bucket  = "my-bucket"
}
```

子模块有自己独立的作用域——模块内部的变量、资源、输出与调用方是隔离的。调用方通过 `variable` 传入参数，通过 `output` 获取返回值，就像调用一个函数一样。

### 嵌套模块（Nested Module）

子模块内部还可以继续调用其他模块，形成**嵌套模块**（Nested Module）结构。例如，一个 `infrastructure` 模块内部调用 `network` 和 `compute` 子模块：

```
根模块
├── module "infrastructure"          ← 子模块
│   ├── module "network"             ← 嵌套子模块
│   │   └── (VPC, Subnet, ...)
│   └── module "compute"             ← 嵌套子模块
│       └── (EC2, ASG, ...)
└── module "monitoring"              ← 子模块
    └── (CloudWatch, ...)
```

嵌套模块和子模块在技术上没有区别——它们都是被 `module` 块调用的模块。"嵌套"只是描述调用层级的深度。需要注意的是，嵌套层数过多会增加配置的复杂度，通常建议控制在 2-3 层以内。

### 标准模块结构

一个规范的 Terraform 模块应该遵循以下文件结构：

```
modules/
  my-module/
    ├── main.tf          # 主要资源定义
    ├── variables.tf     # 输入变量声明
    ├── outputs.tf       # 输出值定义
    ├── LICENSE          # 开源许可证
    ├── README.md        # 模块文档
    └── modules/         # （可选）嵌套子模块
        └── sub-module/
            ├── main.tf
            ├── variables.tf
            └── outputs.tf
```

- `main.tf` — 核心资源和数据源定义
- `variables.tf` — 所有 `variable` 块集中定义，作为模块的输入接口
- `outputs.tf` — 所有 `output` 块集中定义，作为模块的输出接口
- 模块根目录下的所有 `.tf` 文件会被一起加载，文件名只是约定，不影响行为

### 为什么使用模块？

- **复用** — 同一个模块可以在多个项目中使用，避免重复代码
- **封装** — 将复杂的基础设施抽象为简单的接口，隐藏内部实现细节
- **一致性** — 团队通过共享模块确保基础设施遵循统一标准
- **可测试** — 模块可以独立测试和验证

<KillercodaEmbed src="https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-module-basic" />

---

## 使用 module

掌握了模块的概念和结构之后，接下来学习如何在配置中**调用**模块——通过 `module` 块引用已有模块，传入参数并获取输出。

### module 块的基本语法

调用模块的核心是 `module` 块：

```hcl
module "名称" {
  source = "模块来源"

  # 传入参数（对应模块的 variable）
  参数名 = 值
}
```

- `source`（必填）— 指定模块代码的来源
- 其余参数对应模块中 `variable` 块定义的输入变量

### source 来源类型

`source` 参数决定了 Terraform 从哪里加载模块代码。支持多种来源：

| 来源类型 | 示例 | 说明 |
|----------|------|------|
| 本地路径 | `"./modules/network"` | 以 `./` 或 `../` 开头，直接读取本地文件 |
| Terraform Registry | `"terraform-aws-modules/vpc/aws"` | 官方注册表，格式 `namespace/name/provider` |
| GitHub | `"github.com/org/repo"` | 直接引用 GitHub 仓库 |
| 通用 Git | `"git::https://example.com/module.git"` | 支持 HTTPS 和 SSH |
| S3 / GCS | `"s3::https://..."` | 从对象存储加载 |

本地路径是最简单的方式，适合项目内部的模块组织：

```hcl
module "network" {
  source = "./modules/network"   # 相对于当前模块目录
}
```

### version 约束

使用 Terraform Registry 来源时，可以通过 `version` 参数锁定模块版本：

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"    # >= 5.0.0, < 6.0.0
}
```

常见的版本约束写法：

- `"5.0.0"` — 精确版本
- `">= 5.0"` — 最低版本
- `"~> 5.0"` — 悲观约束（允许 5.x，不允许 6.0）
- `">= 5.0, < 6.0"` — 范围约束

::: warning 注意
`version` 仅适用于 Registry 来源。Git 来源通过 `ref` 参数指定版本（分支或 tag）。
:::

### terraform init 与模块

每次新增或修改 `module` 的 `source`/`version` 后，必须运行 `terraform init`：
- 本地模块：建立符号链接
- 远程模块：下载到 `.terraform/modules/` 目录

### 向模块传递参数

`module` 块中除 `source` 和 `version` 外的参数，都会传递给模块的 `variable` 定义：

```hcl
module "data_bucket" {
  source      = "./modules/s3-bucket"
  bucket_name = "${var.project}-data"    # 必填参数
  tags        = { Environment = "prod" } # 可选参数（有 default）
}
```

传参规则：
- 没有 `default` 的 `variable` → **必填**，调用时必须提供
- 有 `default` 的 `variable` → **可选**，不传则使用默认值
- 传入值的类型必须匹配 `variable` 的 `type` 约束

### 引用模块输出

通过 `module.<模块名>.<输出名>` 引用模块暴露的 `output` 值：

```hcl
# 引用模块输出
output "bucket_id" {
  value = module.data_bucket.bucket_id
}

# 将模块输出传给另一个资源
resource "aws_s3_bucket_policy" "policy" {
  bucket = module.data_bucket.bucket_id
  # ...
}
```

模块输出是模块间传递数据的唯一方式——你无法直接访问模块内部的资源属性，必须通过 `output` 暴露。

### 使用 count 批量调用

`count` 元参数可以批量创建多个模块实例：

```hcl
variable "bucket_names" {
  default = ["alpha", "beta", "gamma"]
}

module "buckets" {
  source      = "./modules/s3-bucket"
  count       = length(var.bucket_names)
  bucket_name = var.bucket_names[count.index]
}

# 引用：module.buckets[0].bucket_id
# 批量引用：module.buckets[*].bucket_id
```

### 使用 for_each 批量调用

`for_each` 使用字符串键标识实例，增删元素时更稳定：

```hcl
variable "environments" {
  default = {
    dev  = { suffix = "dev" }
    prod = { suffix = "prod" }
  }
}

module "env_buckets" {
  source      = "./modules/s3-bucket"
  for_each    = var.environments
  bucket_name = "app-${each.value.suffix}"
}

# 引用：module.env_buckets["dev"].bucket_id
```

::: tip count vs for_each
`count` 使用数字索引（`[0]`、`[1]`），删除中间元素会导致后续索引偏移，引发不必要的资源重建。`for_each` 使用字符串键（`["dev"]`、`["prod"]`），增删不影响其他实例。**优先使用 `for_each`**。
:::

### depends_on — 声明隐式依赖

Terraform 通常能自动推断依赖关系——当你在参数中引用了另一个资源或模块的属性时，Terraform 就知道要先创建被引用的对象。但有时候依赖关系是**隐式的**，代码中没有直接引用，Terraform 无法自动推断。这时就需要 `depends_on`。

```hcl
resource "aws_s3_bucket" "config" {
  bucket = "app-config"
}

# 应用模块依赖 config 桶，但代码中没有引用它的属性
module "app" {
  source      = "./modules/app"
  bucket_name = "app-data"     # 没有引用 aws_s3_bucket.config

  depends_on = [aws_s3_bucket.config]
}
```

#### module 是一个整体

module 级别的 `depends_on` 有一个关键特点：**module 被视为一个原子单元**。无论模块内有多少资源，`depends_on` 都把整个模块当作一个整体来处理。具体来说有三种场景：

**场景 1：module depends_on 资源**

```hcl
module "app" {
  source     = "./modules/app"
  depends_on = [aws_s3_bucket.config]
}
```

除非 `aws_s3_bucket.config` 创建完成，否则 `module.app` 内**所有资源和 data** 都被阻塞，一个都不会开始。

**场景 2：资源 depends_on module**

```hcl
resource "aws_s3_bucket" "finalizer" {
  bucket     = "finalizer"
  depends_on = [module.app]
}
```

除非 `module.app` 内**所有资源**都创建完成，`aws_s3_bucket.finalizer` 才会开始创建。不是等模块内某一个资源完成，而是等**全部**完成。

**场景 3：module depends_on module**

```hcl
module "downstream" {
  source     = "./modules/downstream"
  depends_on = [module.app]
}
```

除非 `module.app` 内**所有资源**都创建完成，否则 `module.downstream` 内**所有资源**都被阻塞。两个模块各自作为整体，形成严格的先后顺序。

#### 使用原则

::: warning 谨慎使用 depends_on
`depends_on` 会让 Terraform 生成更保守的执行计划——更多属性值变成 `(known after apply)`，可能导致不必要的资源替换。如果能通过引用表达式（如 `bucket = module.app.bucket_id`）表达依赖，就不需要 `depends_on`。只在 Terraform 确实无法自动推断依赖时才使用。
:::

<KillercodaEmbed src="https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-module-call" />

---

## 重构

TODO
