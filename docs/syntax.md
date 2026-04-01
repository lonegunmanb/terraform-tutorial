---
order: 4
title: Terraform 语法
---

# Terraform 代码的书写

Terraform 使用 HCL（HashiCorp Configuration Language）作为配置语言。HCL 融合了声明式语言的简洁和命令式语言的表达力，是 Terraform 的核心组成部分。

本章将系统介绍 HCL 的语法体系，涵盖以下内容：

## 目录

- [配置语法](#配置语法) — 块、参数、注释等基础语法元素
- [类型](#类型) — Terraform 的类型系统：基本类型与复合类型
- [输入变量 (variable)](#输入变量-variable) — 参数化配置，提高复用性
- [输出值 (output)](#输出值-output) — 导出资源属性供外部使用
- [局部值 (local)](#局部值-local) — 简化重复表达式
- [资源 (resource)](#资源-resource) — Terraform 的核心：声明基础设施组件
- [数据源 (data)](#数据源-data) — 查询已有资源或外部信息
- [表达式](#表达式) — 引用、运算符、条件、循环等
- [重载文件](#重载文件) — override 文件的用法
- [Checks](#checks) — 自定义校验与断言

---

## 配置语法

HCL 的基本构建单元是**块**（Block）、**参数**（Argument）和**注释**（Comment）。

### 块（Block）、标签（Label）与参数（Argument）

块是 HCL 配置的基本结构单元。每个块由**块类型**、零个或多个**标签**和一个**块体**组成：

```hcl
块类型 "标签1" "标签2" {
  # 块体：包含参数和嵌套块
  参数名 = 参数值
}
```

不同的块类型有不同数量的标签，块体内通过 `名称 = 值` 的**参数**赋值语句来配置块的行为：

```hcl
# terraform 块：无标签
terraform {
  required_version = ">= 1.0"
}

# output 块：一个标签（输出名称）
output "greeting" {
  value = "Hello!"
}

# resource 块：两个标签（资源类型、资源名称）
resource "aws_s3_bucket" "data" {
  bucket = "my-bucket"
}
```

标签和参数名都是**标识符**，遵循相同的命名规则——可以包含字母、数字、下划线（`_`）和连字符（`-`），但首字母**不可以为数字**：

```hcl
# ✅ 合法
resource "aws_s3_bucket" "my_bucket" { }
output "server-info" { value = "ok" }
my_project = "app"
server01   = "web"

# ❌ 不合法
# resource "aws_s3_bucket" "1st_bucket" { }  # 标签以数字开头
# 1st_project = "app"                         # 参数名以数字开头
# my project  = "app"                         # 包含空格
# my.project  = "app"                         # 包含点号
```

参数值可以是不同类型：

```hcl
locals {
  project = "my-app"       # 字符串
  enabled = true            # 布尔值
  count   = 3               # 数字
  tags    = {                # Map
    Environment = "dev"
    Team        = "platform"
  }
}
```

::: tip 对齐风格
Terraform 社区推荐使用 `terraform fmt` 命令自动格式化代码，它会对齐同一块内的等号。
:::

### 注释（Comment）

```hcl
# 单行注释（推荐风格）

// 单行注释（C 风格，不推荐）

/*
  多行注释
  可以跨越多行
*/
```

### 字符串与 Heredoc

**普通字符串**使用双引号：

```hcl
name = "Hello, Terraform!"
```

**字符串插值**使用 `${}` 引用表达式：

```hcl
variable "name" {
  default = "World"
}

locals {
  project     = "my-app"
  environment = "dev"
}

greeting  = "Hello, ${var.name}!"
# => "Hello, World!"

full_name = "${local.project}-${local.environment}"
# => "my-app-dev"
```

**Heredoc** 语法用于多行字符串：

```hcl
# <<EOF 保留原始缩进
config = <<EOF
server {
  listen 80;
  server_name example.com;
}
EOF

# <<-EOF 去除公共前导空格（推荐）
config = <<-EOF
  server {
    listen 80;
    server_name example.com;
  }
EOF
```

### 🧪 动手实验

<KillercodaEmbed src="https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-syntax-config-syntax" />

---

## 类型

Terraform 中每个值都有类型，类型决定了值可以在哪里使用以及可以对它应用哪些操作。Terraform 的类型分为**原始类型**、**复杂类型**（集合类型 + 结构化类型），以及特殊的 `any` 和 `null`。

### 原始类型

原始类型有三种：

| 类型 | 描述 | 示例 |
|------|------|------|
| `string` | Unicode 字符串 | `"hello"` |
| `number` | 数字（整数或小数） | `42`、`3.14` |
| `bool` | 布尔值 | `true`、`false` |

`number` 和 `bool` 都可以与 `string` 进行**隐式类型转换**：

```hcl
# number ↔ string
# "42" 可以自动转换为 42，反之亦然
# "3.14" ↔ 3.14

# bool ↔ string
# "true" ↔ true
# "false" ↔ false
```

这意味着将 `"42"` 赋给 `number` 类型的变量不会报错，Terraform 会自动完成转换。

### 集合类型

集合类型包含一组**同一类型**的值。Terraform 支持三种集合类型：

- **`list(...)`** — 有序序列，可用下标访问（从 `0` 开始）

  ```hcl
  variable "zones" {
    type    = list(string)
    default = ["us-east-1a", "us-east-1b", "us-east-1c"]
  }
  # var.zones[0] => "us-east-1a"
  ```

- **`map(...)`** — 键值对集合，键必须是 `string`

  ```hcl
  variable "tags" {
    type = map(string)
    default = {
      Environment = "dev"
      Team        = "platform"
    }
  }
  # var.tags["Environment"] => "dev"
  ```

  ::: tip map 的两种写法
  `map` 值可以用 `{"foo": "bar"}` 或 `{foo = "bar"}` 两种语法。推荐使用 `=` 号——`terraform fmt` 会自动对齐等号，代码更整洁。
  :::

- **`set(...)`** — 无序、不重复的集合，不能用下标访问

  ```hcl
  variable "cidrs" {
    type    = set(string)
    default = ["10.0.0.0/8", "172.16.0.0/12"]
  }
  # contains(var.cidrs, "10.0.0.0/8") => true
  ```

集合类型支持**通配类型缩写**：`list` 等价于 `list(any)`，`map` 等价于 `map(any)`，`set` 等价于 `set(any)`。`any` 要求所有元素是同一类型——赋值时 Terraform 会自动推断并在必要时进行隐式转换。

::: warning "同一类型"比你想象的更严格
`string`、`number`、`bool` 之间可以隐式互转，所以 `["hello", 42, true]` 能赋给 `list(any)`（全部转为 `string`）。但一旦混入**无法互转的类型**，就会报错：

```hcl
# ❌ 报错！string 和 list 无法转换为同一类型
locals {
  bad_list = tolist(["hello", ["a", "b"]])
}
# Error: Invalid value for "v" parameter: cannot convert tuple to list
# of any single type

# ❌ 报错！string 和 object 不是同一类型
variable "bad_map" {
  type = map(any)
  default = {
    name   = "alice"
    config = { port = 8080 }
  }
}
# Error: all map elements must have the same type
```

这种情况在 `map` 中尤其容易踩坑——看起来像一个普通 map，但值的类型不一致就会失败。如果你需要每个键有不同类型的值，应该用 `object` 而不是 `map`。
:::

### 结构化类型

结构化类型允许多个**不同类型**的值组成一个复合类型：

- **`object({...})`** — 由命名属性组成，每个属性有独立类型

  ```hcl
  variable "server" {
    type = object({
      name   = string
      port   = number
      active = bool
    })
    default = {
      name   = "web-01"
      port   = 8080
      active = true
    }
  }
  # var.server.name => "web-01"
  ```

  赋给 `object` 的值必须包含所有必填属性，但**多余的属性会被丢弃**。

- **`tuple([...])`** — 定长序列，每个位置有独立类型

  ```hcl
  variable "record" {
    type    = tuple([string, number, bool])
    default = ["hello", 42, true]
  }
  # var.record[0] => "hello"
  # var.record[1] => 42
  ```

::: info object vs map，tuple vs list
- `map` 的所有值类型相同，`object` 的每个属性可以是不同类型
- `list` 的所有元素类型相同，`tuple` 的每个位置可以是不同类型
- `object` ↔ `map`、`tuple` ↔ `list` 之间在满足条件时可以隐式转换
:::

### object 的 optional 成员

自 Terraform 1.3 起，`object` 中可以使用 `optional` 声明可选属性：

```hcl
variable "config" {
  type = object({
    name     = string                    # 必填
    port     = optional(number, 8080)    # 可选，默认 8080
    debug    = optional(bool, false)     # 可选，默认 false
  })
}
```

`optional` 有两个参数：
1. **类型**（必填）— 属性的类型
2. **默认值**（选填）— 省略该属性时使用的值。未指定默认值时，默认为 `null`

这对于包含大量属性的 `object` 尤其有用——用户只需提供关心的属性，其余自动获得合理的默认值：

```hcl
variable "database" {
  type = object({
    engine  = string
    version = optional(string, "14")
    port    = optional(number, 5432)
    config  = optional(object({
      max_connections = optional(number, 100)
      ssl_enabled     = optional(bool, true)
    }), {})
  })
}

# 只需提供必填属性
# database = { engine = "postgresql" }
# 其他属性自动获得默认值：version="14", port=5432, config.max_connections=100, ...
```

### any 与 null

- **`any`** — 类型占位符，不是真正的类型。Terraform 会根据赋值推断实际类型。声明 `type = any` 表示接受任意类型。

- **`null`** — 表示数据缺失，无类型。将参数设为 `null` 时，如果有默认值则使用默认值，如果是必填参数则报错。`null` 在条件表达式中很有用：

  ```hcl
  # 条件不满足时跳过赋值（使用默认值）
  error_document = var.legacy ? "ERROR.HTM" : null
  ```

### 🧪 动手实验

<KillercodaEmbed src="https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-syntax-type" />

---

## 输入变量 (variable)

<!-- TODO: variable 块、类型约束、默认值、validation、sensitive -->

---

## 输出值 (output)

<!-- TODO: output 块、description、sensitive、depends_on -->

---

## 局部值 (local)

<!-- TODO: locals 块、表达式计算、使用场景 -->

---

## 资源 (resource)

<!-- TODO: resource 块、meta-arguments (count, for_each, depends_on, lifecycle)、provisioner -->

---

## 数据源 (data)

<!-- TODO: data 块、查询已有资源、与 resource 的区别 -->

---

## 表达式

<!-- TODO: 引用、算术运算、字符串模板、条件表达式、for 表达式、splat -->

---

## 重载文件

<!-- TODO: override files 的作用和使用场景 -->

---

## Checks

<!-- TODO: check 块、assert、precondition/postcondition -->
