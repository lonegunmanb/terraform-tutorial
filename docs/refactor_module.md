---
order: 8
title: 代码重构
---

# 代码重构

随着 Terraform 配置规模的增长，重构变得不可避免——重命名资源、提取模块、将已有基础设施纳入管理、从管理中移除不再需要的资源。

然而 Terraform 是声明式语言，它通过**资源地址**（如 `aws_s3_bucket.data`）将代码中的定义与状态文件中的实际资源关联起来。如果你直接修改资源名称或移动资源到模块中，Terraform 会认为旧资源被删除、新资源需要创建——这意味着**先销毁再重建**，对生产环境来说可能是灾难性的。

Terraform 提供了三种配置块来安全地完成这类重构操作：

## 目录

- [import 块](#import-块) — 将已有基础设施纳入 Terraform 管理
- [removed 块](#removed-块) — 从 Terraform 管理中移除资源，但不销毁
- [moved 块](#moved-块) — 重命名或移动资源，不销毁不重建

---

## import 块

在实际工作中，团队往往不是从零开始使用 Terraform——可能已经有大量通过控制台手动创建、或由其他工具管理的基础设施资源。`import` 块允许你将这些已存在的资源纳入 Terraform 管理，而不需要销毁重建。

### 基本语法

`import` 块需要两个参数：`to` 指定资源在 Terraform 中的目标地址，`id` 指定资源在云平台上的唯一标识符：

```hcl
import {
  to = aws_s3_bucket.data
  id = "my-existing-bucket"
}

resource "aws_s3_bucket" "data" {
  bucket = "my-existing-bucket"
}
```

执行 `terraform plan` 时，Terraform 会通过 Provider 用 `id` 查询该资源的当前状态，然后将其与 `resource` 块中的配置对比。如果配置与实际状态一致，`plan` 的输出会显示导入操作而非创建操作：

```
Plan: 1 to import, 0 to add, 0 to change, 0 to destroy.
```

执行 `terraform apply` 后，资源的状态会被写入状态文件，此后 Terraform 就可以正常管理它了。

### 自动生成资源配置

手动编写已有资源的 `resource` 块可能很繁琐——你需要查阅每个属性的当前值。Terraform 提供了 `-generate-config-out` 标志来自动生成配置：

```bash
# 只写 import 块，不写 resource 块
# import.tf
import {
  to = aws_s3_bucket.data
  id = "my-existing-bucket"
}
```

```bash
terraform plan -generate-config-out=generated.tf
```

Terraform 会查询资源的当前状态，并将对应的 `resource` 块写入 `generated.tf`。生成的配置可能需要手动调整（如移除只读属性），但大大减少了工作量。

### 导入到子模块中的资源

`import` 块的 `to` 地址可以指向子模块中的资源——使用完整的模块路径：

```hcl
import {
  to = module.storage.aws_s3_bucket.data
  id = "my-existing-bucket"
}
```

这适用于将已有资源导入到一个已经定义好的模块中。

### 批量导入

结合 `for_each` 可以批量导入多个同类型资源：

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

resource "aws_s3_bucket" "this" {
  for_each = local.buckets
  bucket   = each.value
}
```

### id 必须在 plan 阶段已知

`id` 参数的值必须在 `terraform plan` 阶段就能确定——不能引用尚未创建的资源的属性。可以使用字面量、输入变量、局部值等 plan 阶段已知的值。

### 导入完成后

`import` 块是一次性的——资源成功导入后，你可以保留 `import` 块作为历史记录，也可以删除它。再次执行 `plan` 时，Terraform 会发现资源已存在于状态中，`import` 块不会重复执行。

::: warning import 块只能在根模块中使用
`import` 块**只能声明在根模块**的 `.tf` 文件中。如果将其写在子模块中，Terraform 会报错：

```
Error: Invalid import configuration

An import block was detected in "module.child". Import blocks are only
allowed in the root module.
```

虽然 `import` 块必须写在根模块中，但 `to` 地址可以通过 `module.xxx.resource_type.name` 的形式指向子模块内的资源。
:::

---

## removed 块

与 `import` 相反，`removed` 块用于将资源从 Terraform 管理中**移除**。移除后，Terraform 不再跟踪该资源，但可以选择**不销毁**实际的基础设施对象——这在将资源的管理权限移交给其他团队或工具时非常有用。

### 基本语法

`removed` 块取代原有的 `resource` 块，`from` 指定资源的原始地址，`lifecycle` 中的 `destroy` 控制是否销毁实际资源：

```hcl
# 原来的代码：
# resource "aws_s3_bucket" "legacy" {
#   bucket = "legacy-data-bucket"
# }

# 替换为：
removed {
  from = aws_s3_bucket.legacy

  lifecycle {
    destroy = false   # 不销毁实际资源，只从状态中移除
  }
}
```

执行 `terraform plan` 会显示：

```
# aws_s3_bucket.legacy will no longer be managed by Terraform, but
# will not be destroyed
# (destroy = false is set in the configuration)
```

### destroy 参数

`destroy` 参数控制移除时的行为：

- **`destroy = false`**（推荐）— 仅从状态文件中移除记录，不销毁实际资源。资源继续存在于云平台上，只是 Terraform 不再管理它
- **`destroy = true`**（默认值）— 从状态文件中移除记录，**并销毁**实际资源。效果类似于直接删除 `resource` 块

::: tip 什么时候用 destroy = true？
如果你的意图就是销毁资源，直接删除 `resource` 块更简单。`removed` 块在 `destroy = true` 模式下的主要价值在于可以配合 `provisioner` 执行销毁时的清理操作。
:::

### 与 terraform state rm 的区别

在 `removed` 块出现之前，从状态中移除资源需要使用 CLI 命令 `terraform state rm`。两者的主要区别是：

| 对比 | `removed` 块 | `terraform state rm` |
|------|-------------|---------------------|
| 方式 | 声明式（写在代码中） | 命令式（手动执行） |
| 可追溯 | 代码历史中可见 | 需要额外记录 |
| 团队协作 | 通过代码审查流程 | 需要单独操作 |
| 版本要求 | Terraform v1.7+ | 所有版本 |

`removed` 块是声明式的——写入代码、提交审查、团队 apply 后自然生效。而 `terraform state rm` 是一个临时操作，不会留下代码痕迹，团队成员也无法通过代码历史了解发生了什么。

### 在模块新版本中移除资源

`removed` 块一个非常实用的场景是：**模块维护者在新版本中移除某个资源**，同时确保使用者升级时不会意外销毁已有资源。

假设你维护的模块在 v1 中包含一个日志桶：

```hcl
# modules/app/main.tf (v1)
resource "aws_s3_bucket" "logs" {
  bucket = "${var.app_name}-logs"
}
```

在 v2 中决定不再管理日志桶，可以用 `removed` 替换：

```hcl
# modules/app/main.tf (v2)
removed {
  from = aws_s3_bucket.logs

  lifecycle {
    destroy = false
  }
}
```

现有用户升级到 v2 后，`terraform apply` 会将日志桶从状态中移除但不销毁。新用户使用 v2 时，`removed` 块不产生任何效果（状态中本就没有这个资源）。

::: info removed 块可以在任意模块中使用
与 `import` 块不同，`removed` 块**不限于根模块**——它可以声明在任何模块中。`from` 地址相对于声明所在的模块解析。

这使得模块维护者可以在子模块内部使用 `removed` 块，调用方升级模块版本时自动生效，无需做任何修改。
:::

---

## moved 块

`moved` 块解决的是 Terraform 中最常见的重构难题：**重命名或移动资源时，如何避免"删旧建新"**。

当你修改 `resource` 块的名称标签（如把 `aws_s3_bucket.data` 改为 `aws_s3_bucket.app_data`），Terraform 会认为旧资源被删除、新资源需要创建。在 `plan` 中你会看到一个 `-`（销毁）加一个 `+`（创建），而不是原地重命名。

`moved` 块告诉 Terraform："这只是同一个资源换了个名字"：

```hcl
moved {
  from = aws_s3_bucket.data
  to   = aws_s3_bucket.app_data
}
```

Terraform 在执行 `plan` 时会检查状态文件中是否存在 `from` 地址的资源。如果存在，Terraform 会将其重命名为 `to` 地址，**不销毁、不重建**。

### 重命名资源

最简单的场景——给资源起一个更好的名字：

```hcl
# 原来的代码：
# resource "aws_instance" "web" { ... }

# 重命名为更精确的名称：
resource "aws_instance" "api_server" {
  # ...（配置不变）
}

moved {
  from = aws_instance.web
  to   = aws_instance.api_server
}
```

`terraform plan` 会显示：

```
# aws_instance.web has moved to aws_instance.api_server
    resource "aws_instance" "api_server" {
        id            = "i-0abc123def456"
        # (其他属性不变)
    }
```

`moved` 块对资源的**所有实例**生效——如果资源使用了 `count` 或 `for_each`，所有实例会一起移动，无需逐个指定。

### 重命名模块调用

与资源重命名类似，修改 `module` 块的名称也可以用 `moved` 实现：

```hcl
# 原来：module "bucket" { ... }
# 改为更清晰的名称：
module "app_storage" {
  source = "./modules/s3-bucket"
  # ...
}

moved {
  from = module.bucket
  to   = module.app_storage
}
```

模块作为整体移动——模块内所有资源的地址前缀从 `module.bucket` 变为 `module.app_storage`，所有资源都不会被销毁或重建。

### 为已有资源启用 count 或 for_each

当你决定将一个单实例资源改为使用 `count` 或 `for_each` 时，资源地址会从 `aws_instance.web` 变为 `aws_instance.web[0]` 或 `aws_instance.web["key"]`。`moved` 块可以将旧实例映射到新地址：

```hcl
# 原来是单实例
# resource "aws_instance" "web" { ... }

# 改为 for_each
resource "aws_instance" "web" {
  for_each = tomap({
    small = { instance_type = "t3.micro" }
    large = { instance_type = "m5.large" }
  })

  instance_type = each.value.instance_type
  # ...
}

# 将原来的单实例映射到 "small" 键
moved {
  from = aws_instance.web
  to   = aws_instance.web["small"]
}
```

同样地，可以在 `count` 和 `for_each` 之间切换：

```hcl
# 从 count 迁移到 for_each
moved {
  from = aws_instance.web[0]
  to   = aws_instance.web["primary"]
}

moved {
  from = aws_instance.web[1]
  to   = aws_instance.web["secondary"]
}
```

::: tip
当你给一个没有 `count` 的资源添加 `count` 时，Terraform 会自动提议将原实例移到 `[0]`。但建议显式写出 `moved` 块，让变更意图更清晰。
:::

### 将资源移入模块

随着代码规模增长，你可能希望将根模块中的一些资源提取到子模块中。`moved` 块可以指定跨模块的地址：

```hcl
# 原来在根模块中：
# resource "aws_s3_bucket" "data" { ... }
# resource "aws_s3_bucket" "logs" { ... }

# 提取到子模块后：
module "storage" {
  source = "./modules/storage"
  # ...
}

moved {
  from = aws_s3_bucket.data
  to   = module.storage.aws_s3_bucket.data
}

moved {
  from = aws_s3_bucket.logs
  to   = module.storage.aws_s3_bucket.logs
}
```

### 拆分模块

当一个模块过大时，可以将其拆分为多个子模块。原模块变成一个"垫片"（shim），只负责调用新的子模块，并用 `moved` 块记录资源的迁移路径：

```hcl
# 原模块拆分后，变成调用两个新模块的垫片：
module "compute" {
  source = "../modules/compute"
  # ...
}

module "network" {
  source = "../modules/network"
  # ...
}

# 记录每个资源移到了哪里
moved {
  from = aws_instance.web
  to   = module.compute.aws_instance.web
}

moved {
  from = aws_vpc.main
  to   = module.network.aws_vpc.main
}

moved {
  from = aws_subnet.public
  to   = module.network.aws_subnet.public
}
```

现有用户升级到这个版本时，Terraform 根据 `moved` 块自动重定向所有资源地址，不会触发任何销毁或重建。

### 链式 moved 块

如果同一个资源经历了多次重命名，可以用链式 `moved` 块记录完整历史。Terraform 会按链依次解析，支持从任何历史地址升级：

```hcl
moved {
  from = aws_instance.web
  to   = aws_instance.api
}

moved {
  from = aws_instance.api
  to   = aws_instance.api_server
}
```

使用旧版本（资源地址为 `aws_instance.web`）的配置升级时，Terraform 会依次解析：`web` → `api` → `api_server`，最终正确地将资源映射到 `aws_instance.api_server`。

### moved 块可以在任意模块中使用

与 `import` 不同，`moved` 块**不限于根模块**——它可以声明在任何模块中。`from` 和 `to` 地址相对于声明所在的模块解析。

这意味着模块维护者可以在模块内部添加 `moved` 块，使得所有调用方在升级模块版本时自动获得资源地址的迁移，无需调用方做额外操作。

模块中的 `moved` 块只能引用**自身及其子模块**中的资源——不能跨越模块边界引用父模块或兄弟模块的资源。

::: warning 移除 moved 块是破坏性变更
`moved` 块一旦删除，仍在使用旧地址的配置在下一次 `plan` 时会看到"删旧建新"的操作。

对于公开发布的模块，强烈建议**永久保留**所有历史 `moved` 块，确保任何版本的用户都能安全升级。

对于私有模块，当确认所有使用者都已成功 `apply` 过新版本后，可以安全地移除 `moved` 块。
:::

### 注意事项

- **不能将 `resource` 移为 `data`** — `moved` 块不支持在托管资源和数据源之间转换
- **同一模块包** — `moved` 块只能在同一个模块包内使用（模块及其子模块），不能跨独立分发的模块包引用
- **某些 Provider 支持跨类型移动** — 个别 Provider 允许将一种资源类型移到另一种，但这取决于具体的 Provider 实现，请查阅 Provider 文档

---

## 对比总结

| 配置块 | 用途 | 是否销毁资源 | 可声明位置 | 最低版本 |
|--------|------|-------------|-----------|---------|
| `import` | 将已有资源纳入管理 | 否 | 仅根模块 | v1.5 |
| `removed` | 从管理中移除资源 | 可选（`destroy` 参数） | 任意模块 | v1.7 |
| `moved` | 重命名或移动资源 | 否 | 任意模块 | v1.1 |
| ~~直接改代码~~ | ~~重命名/删除~~ | **是** | — | — |

## 🧪 动手实验

<KillercodaEmbed src="https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-refactor" />
