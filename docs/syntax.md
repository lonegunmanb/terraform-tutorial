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
- [表达式](#表达式) — 引用、运算符、条件、循环等
- [输入变量 (variable)](#输入变量-variable) — 参数化配置，提高复用性
- [输出值 (output)](#输出值-output) — 导出资源属性供外部使用
- [局部值 (local)](#局部值-local) — 简化重复表达式
- [资源 (resource)](#资源-resource) — Terraform 的核心：声明基础设施组件
- [数据源 (data)](#数据源-data) — 查询已有资源或外部信息
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

## 表达式

表达式是 Terraform 配置中用于计算值的核心机制。前面我们已经用到了字符串字面量、变量引用等简单表达式，本节将系统介绍 Terraform 支持的各种表达式。

### 引用

在 Terraform 中，可以通过以下方式引用各种命名对象的值：

| 引用形式 | 含义 |
|----------|------|
| `var.<NAME>` | 输入变量 |
| `local.<NAME>` | 局部值 |
| `resource_type.name` | 资源属性 |
| `data.data_type.name` | 数据源属性 |
| `module.<NAME>` | 模块输出 |
| `self` | 在 provisioner/connection 中引用当前资源 |
| `terraform.workspace` | 当前工作区名称 |
| `path.module` | 当前模块的文件系统路径 |
| `path.root` | 根模块的文件系统路径 |
| `path.cwd` | 当前工作目录的文件系统路径 |

```hcl
locals {
  project = "demo"
}

output "info" {
  value = "项目: ${local.project}, 工作区: ${terraform.workspace}"
}
```

### 算术与逻辑运算符

运算符要么是把两个值计算为第三个值（二元操作符），要么是把一个值转换为另一个值（一元操作符）。

当一个表达式中含有多个运算符时，它们的优先级顺序为：

1. `!`，`-` (负号)
2. `*`，`/`，`%`
3. `+`，`-` (减号)
4. `>`，`>=`，`<`，`<=`
5. `==`，`!=`
6. `&&`
7. `||`

可以使用小括号覆盖默认优先级，例如 `1+2*3` 会被计算为 `7`，而 `(1+2)*3` 为 `9`。

#### 算术运算符

- `a + b`：返回 a 与 b 的和
- `a - b`：返回 a 与 b 的差
- `a * b`：返回 a 与 b 的积
- `a / b`：返回 a 与 b 的商
- `a % b`：返回 a 除以 b 的余数（取模），一般仅在两者为整数时有效
- `-a`：返回 a 的相反数

```hcl
locals {
  sum       = 3 + 4       # 7
  remainder = 10 % 3      # 1
  negative  = -(5)        # -5
}
```

#### 相等性运算符

- `a == b`：如果 a 与 b 类型与值都相等返回 `true`，否则返回 `false`
- `a != b`：与 `==` 相反

#### 比较运算符

- `a < b`：如果 a 比 b 小则为 `true`
- `a > b`：如果 a 比 b 大则为 `true`
- `a <= b`：如果 a 小于等于 b 则为 `true`
- `a >= b`：如果 a 大于等于 b 则为 `true`

#### 逻辑运算符

- `a || b`：a 或 b 中有至少一个为 `true` 则为 `true`
- `a && b`：a 与 b 都为 `true` 则为 `true`
- `!a`：如果 a 为 `true` 则为 `false`，反之亦然

```hcl
locals {
  is_prod     = true
  has_budget  = false
  should_warn = local.is_prod && !local.has_budget  # true
}
```

### 条件表达式

条件表达式根据布尔条件在两个值中选择一个：

```hcl
condition ? true_val : false_val
```

如果 `condition` 为 `true`，结果是 `true_val`，否则为 `false_val`。两个候选值的类型必须相同。

```hcl
variable "environment" {
  type    = string
  default = "dev"
}

locals {
  instance_type = var.environment == "prod" ? "m5.large" : "t3.micro"
}
```

一个常见用法是用默认值替代非法值：

```hcl
# 如果 var.name 为空字符串，使用默认值
name = var.name != "" ? var.name : "default-name"
```

::: tip
上面的表达式推荐写为：`coalesce(var.name, "default-name")`
:::

条件表达式与 `null` 结合可以实现"可选赋值"——条件不满足时跳过赋值，使用资源属性的默认值：

```hcl
error_document = var.legacy ? "ERROR.HTM" : null
```

### 函数调用

Terraform 支持在表达式中使用内建函数。通用语法是：

```hcl
函数名(参数1, 参数2, ...)
```

例如 `min` 函数接收任意多个数值参数，返回最小值：

```hcl
min(55, 3453, 2)  # => 2
```

#### 展开函数入参

如果想把列表或元组的元素作为参数传递给函数，可以使用展开符 `...`：

```hcl
min([55, 2453, 2]...)  # => 2
```

展开符由三个独立的 `.` 组成，只能用在函数调用场景中。

::: info 常用内建函数
Terraform 提供了丰富的内建函数，按类别包括：

- **字符串**：`upper`、`lower`、`format`、`join`、`split`、`trimspace`、`replace`、`regex`
- **集合**：`length`、`contains`、`merge`、`flatten`、`keys`、`values`、`lookup`、`element`、`concat`、`distinct`、`sort`
- **数值**：`min`、`max`、`abs`、`ceil`、`floor`、`log`、`pow`
- **类型转换**：`tostring`、`tonumber`、`tobool`、`tolist`、`toset`、`tomap`
- **编码**：`jsonencode`、`jsondecode`、`yamlencode`、`base64encode`
- **文件**：`file`、`fileexists`、`templatefile`、`basename`、`dirname`
- **日期**：`timestamp`、`formatdate`、`timeadd`
- **逻辑**：`can`、`try`、`coalesce`、`coalescelist`

完整列表参见 [Terraform 函数文档](https://developer.hashicorp.com/terraform/language/functions)。
:::

### 字符串模板

字符串模板允许在字符串中嵌入表达式或通过循环动态构造字符串。

#### 插值 (Interpolation)

`${...}` 序列计算花括号之间的表达式的值，将结果转换为字符串后插入模板：

```hcl
"Hello, ${var.name}!"
# var.name = "Juan" => "Hello, Juan!"
```

#### 指令 (Directive)

`%{...}` 序列用于在字符串内部进行条件判断或遍历。

**if/else/endif 指令**根据布尔表达式选择模板：

```hcl
"Hello, %{ if var.name != "" }${var.name}%{ else }unnamed%{ endif }!"
```

**for/endfor 指令**遍历集合，用每个元素渲染模板，然后拼接起来：

```hcl
<<-EOT
%{ for ip in var.ip_list ~}
server ${ip}
%{ endfor ~}
EOT
```

::: tip 去除空白的 ~ 符号
所有模板序列的首尾都可以添加 `~` 符号。`~` 会去除模板序列相邻一侧的空白（空格和换行），常与 Heredoc 配合使用以控制输出格式。
:::

如果需要输出字面量 `${` 或 `%{`，重复第一个字符即可：`$${` 和 `%%{`。

### for 表达式

`for` 表达式将一种复合类型映射成另一种。输入类型中的每个元素都会被映射为一个或零个结果。

**输出元组**——用方括号包裹：

```hcl
[for s in var.list : upper(s)]
# var.list = ["hello", "world"] => ["HELLO", "WORLD"]
```

**输出对象**——用花括号包裹，使用 `=>` 分隔键值：

```hcl
{for s in var.list : s => upper(s)}
# var.list = ["hello"] => { "hello" = "HELLO" }
```

**带过滤的 for**——添加 `if` 子句过滤元素：

```hcl
[for s in var.list : upper(s) if s != ""]
```

**遍历 map/object**——迭代器表示为两个临时变量（键和值）：

```hcl
[for k, v in var.map : "${k}=${v}"]
```

**分组 (group by)**——在输出对象时使用 `...` 将同键的值聚合为列表：

```hcl
{for s in var.list : substr(s, 0, 1) => s...}
# ["apple", "avocado", "banana"]
# => { "a" = ["apple", "avocado"], "b" = ["banana"] }
```

### Splat 表达式

Splat 表达式提供了一种简洁的方式来提取列表中所有元素的某个属性，等价于特定模式的 `for` 表达式。

假设 `var.list` 包含一组对象，每个对象有 `id` 属性，以下两种写法等价：

```hcl
# for 表达式
[for o in var.list : o.id]

# splat 表达式
var.list[*].id
```

`[*]` 符号迭代列表中每一个元素，并返回它们在 `.` 右边的属性值。

如果 splat 表达式被用于一个既不是列表又不是元组的值，该值会被自动包装成单元素列表。这在访问可能带有 `count` 参数的资源时很有用：

```hcl
# 不论 aws_instance.example 是否定义了 count，都能正确返回 id 列表
aws_instance.example[*].id
```

::: warning 避免旧式 splat 语法
Terraform 有一种使用 `.*` 的旧式 splat 语法。对于简单的单层属性访问（如 `var.list.*.id`），旧语法和新语法 `var.list[*].id` 结果相同。但在**链式访问嵌套属性**时，两者行为不同：

```hcl
variable "servers" {
  default = [
    { interfaces = [{ ip = "10.0.0.1" }, { ip = "10.0.0.2" }] },
    { interfaces = [{ ip = "10.0.1.1" }, { ip = "10.0.1.2" }] },
  ]
}

# 新语法 [*]：对每个元素完整求值 interfaces[0].ip
var.servers[*].interfaces[0].ip
# 等价于 [for s in var.servers : s.interfaces[0].ip]
# => ["10.0.0.1", "10.0.1.1"]   ← 每个 server 的第一个接口 IP

# 旧语法 .*：[0] 跳出 splat，作用在 splat 的结果列表上
var.servers.*.interfaces[0]
# 等价于 [for s in var.servers : s.interfaces][0]
# => [{ ip = "10.0.0.1" }, { ip = "10.0.0.2" }]  ← 第一个 server 的所有接口

var.servers.*.interfaces[0].ip
# ❌ Error: Unsupported attribute
# [0] 返回的是一个列表，无法再 .ip
```

简单来说：`[*]` 把后续的 `.` 和 `[]` 都应用到**每个元素**上，而 `.*` 只 splat `.` 属性访问，`[]` 下标会跳出 splat 作用在结果列表上，导致后续链式访问出错。始终使用 `[*]` 即可。
:::

### 🧪 动手实验

<KillercodaEmbed src="https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-syntax-expression" />

---

## 输入变量 (variable)

输入变量是 Terraform 配置的参数化机制。把一组 Terraform 代码想象成一个函数，输入变量就是函数的入参——通过变量，我们可以让同一份代码在不同场景下创建不同的基础设施。

### variable 块

输入变量用 `variable` 块定义，紧跟关键字的标签是变量名：

```hcl
variable "image_id" {
  type        = string
  description = "机器镜像 ID"
}

variable "docker_ports" {
  type = list(object({
    internal = number
    external = number
    protocol = string
  }))
  default = [
    {
      internal = 8300
      external = 8300
      protocol = "tcp"
    }
  ]
}
```

在代码中通过 `var.<NAME>` 引用变量值：

```hcl
resource "aws_instance" "web" {
  ami = var.image_id
}
```

在同一个模块（同一目录下的所有 `.tf` 文件）中，变量名必须唯一。以下关键字**不可以**作为变量名：`source`、`version`、`providers`、`count`、`for_each`、`lifecycle`、`depends_on`、`locals`。

### 类型约束 (type)

通过 `type` 参数限制变量接受的值的类型：

```hcl
variable "name" {
  type = string
}

variable "ports" {
  type = list(number)
}

variable "server" {
  type = object({
    name = string
    port = number
  })
}
```

关于各种类型的详细说明，参见前文[类型](#类型)一节。

### 默认值 (default)

`default` 定义变量在未被赋值时使用的默认值：

```hcl
variable "region" {
  type    = string
  default = "us-east-1"
}
```

没有默认值的变量在执行时**必须**被赋值，否则 Terraform 会在交互界面提示输入。

### 描述 (description)

`description` 向调用者说明变量的用途。当 Terraform 需要在命令行提示输入时，会显示这段描述：

```hcl
variable "image_id" {
  type        = string
  description = "The id of the machine image (AMI) to use for the server."
}
```

```
$ terraform apply
var.image_id
  The id of the machine image (AMI) to use for the server.

  Enter a value:
```

::: tip
描述应站在**使用者**的角度编写，而非维护者。描述不是代码注释——它是面向模块调用者的 API 文档。
:::

### 断言 (validation)

`validation` 块允许对输入值进行自定义校验。`condition` 表达式为 `true` 时合法，为 `false` 时 Terraform 返回 `error_message` 中的错误信息：

```hcl
variable "instance_count" {
  type = number

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "instance_count 必须在 1 到 10 之间。"
  }
}
```

结合 `can` 函数可以捕获表达式执行中的错误，常用于正则校验：

```hcl
variable "image_id" {
  type = string

  validation {
    condition     = can(regex("^ami-", var.image_id))
    error_message = "image_id 必须以 \"ami-\" 开头。"
  }
}
```

一个变量可以有**多个** `validation` 块，所有校验都必须通过：

```hcl
variable "bucket_name" {
  type = string

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "长度必须在 3-63 个字符之间。"
  }

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.bucket_name))
    error_message = "只能包含小写字母、数字、点和连字符，且必须以字母或数字开头和结尾。"
  }
}
```

#### 跨变量引用

自 Terraform v1.9 起，`condition` 中可以引用**其他变量**，不再局限于当前变量自身。这使得跨变量的联合校验成为可能：

```hcl
variable "min_count" {
  type    = number
  default = 1
}

variable "max_count" {
  type    = number
  default = 10

  validation {
    condition     = var.max_count >= var.min_count
    error_message = "max_count（${var.max_count}）不能小于 min_count（${var.min_count}）。"
  }
}
```

::: warning 注意循环引用
跨变量校验时，如果两个变量的 `validation` 互相引用对方，会形成循环依赖，Terraform 将报错。确保引用关系是**单向**的：

```hcl
# ✅ 单向引用：max_count 的校验引用 min_count
variable "min_count" { type = number }
variable "max_count" {
  type = number
  validation {
    condition     = var.max_count >= var.min_count
    error_message = "max_count 不能小于 min_count。"
  }
}

# ❌ 循环引用：两者互相引用，会报错
# variable "a" {
#   validation { condition = var.a < var.b ... }
# }
# variable "b" {
#   validation { condition = var.b > var.a ... }
# }
```
:::

### 敏感值 (sensitive)

将 `sensitive` 设为 `true` 后，Terraform 在 `plan` 和 `apply` 输出中会用 `(sensitive value)` 隐藏该变量的值：

```hcl
variable "db_password" {
  type      = string
  sensitive = true
}
```

```
  + resource "aws_db_instance" "main" {
      + password = (sensitive value)
    }
```

::: warning
`sensitive` 只影响命令行输出。Terraform **仍然会将敏感数据以明文记录在状态文件中**——任何能访问状态文件的人都能读取这些值。
:::

### 禁止为空 (nullable)

`nullable`（默认 `true`）控制变量是否接受 `null` 值：

```hcl
variable "region" {
  type     = string
  default  = "us-east-1"
  nullable = false
}
```

当 `nullable = false` 时，即使调用者显式传入 `null`，Terraform 也会使用默认值，确保变量在模块内永远不为空。

### 临时变量 (ephemeral)

自 Terraform v1.10 起，可以将变量标记为 `ephemeral`。临时变量的值在当前 Terraform 运行期间可用，但**不会被记录到状态文件和计划文件中**：

```hcl
variable "session_token" {
  type      = string
  ephemeral = true
}
```

这对于短生命周期的数据特别有用，例如临时令牌、会话标识符等——它们只需在执行期间存在，不应被持久化。

#### ephemeral 与 sensitive 的区别

| 特性 | `sensitive` | `ephemeral` |
|------|------------|-------------|
| plan/apply 输出中隐藏 | ✅ | ✅ |
| 状态文件中记录 | ✅（明文） | ❌ |
| 计划文件中记录 | ✅ | ❌ |
| 运行结束后可读取 | ✅（从状态文件） | ❌ |

简单来说：`sensitive` 只是"遮住眼睛"，数据仍然存在于状态文件中；`ephemeral` 则彻底不持久化，运行结束后数据消失。

#### 引用限制

临时变量只能在以下上下文中被引用，否则 Terraform 会报错：

- 另一个临时变量
- `local` 表达式
- 临时输出值（`ephemeral = true` 的 `output`）
- `provider` 块中的参数
- `provisioner` 和 `connection` 块
- `precondition` 和 `postcondition` 中的 `condition`

```hcl
variable "api_token" {
  type      = string
  ephemeral = true
}

# ✅ 可以在 local 中引用
locals {
  auth_header = "Bearer ${var.api_token}"
}

# ✅ 可以在 provider 中引用
provider "http" {
  token = var.api_token
}

# ❌ 不能直接赋给普通资源属性（会被写入状态文件）
# resource "some_resource" "example" {
#   token = var.api_token  # Error!
# }
```

### 对输入变量赋值

有四种方式为变量赋值：

**1. 命令行参数 (`-var`)**

```bash
terraform apply -var="image_id=ami-abc123"
terraform apply -var='tags={"env":"prod","team":"platform"}'
```

**2. 参数文件 (`.tfvars`)**

```hcl
# prod.tfvars
image_id            = "ami-abc123"
availability_zones  = ["us-east-1a", "us-east-1b"]
```

```bash
terraform apply -var-file="prod.tfvars"
```

名为 `terraform.tfvars` 或 `*.auto.tfvars` 的文件会被**自动加载**，无需 `-var-file`。

**3. 环境变量 (`TF_VAR_`)**

```bash
export TF_VAR_image_id=ami-abc123
terraform plan
```

环境变量特别适合在 CI/CD 流水线中传递敏感数据。

**4. 交互式输入**

当以上方式都未提供值且变量没有默认值时，Terraform 会在终端提示输入。

### 赋值优先级

当多种方式同时为同一变量赋值时，后者覆盖前者（优先级从低到高）：

1. 环境变量
2. `terraform.tfvars`
3. `terraform.tfvars.json`
4. `*.auto.tfvars` / `*.auto.tfvars.json`（按文件名字母序）
5. `-var` 和 `-var-file` 命令行参数（按出现顺序）

### 🧪 动手实验

<KillercodaEmbed src="https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-syntax-variable" />

---

## 输出值 (output)

我们在介绍输入变量时提到过，如果我们把一组 Terraform 代码想象成一个函数，那么输入变量就是函数的入参；函数可以有入参，也可以有返回值——输出值就是 Terraform 代码的返回值。

与大部分语言的函数只支持单返回值不同，Terraform 支持**多返回值**。`apply` 成功后，命令行会输出所有定义的输出值。也可以随时通过 `terraform output` 命令查看当前状态文件中的输出值。

### output 块

输出值使用 `output` 块定义，紧跟关键字的标签是输出名称：

```hcl
output "instance_ip_addr" {
  value = aws_instance.server.private_ip
}
```

`value` 参数是必填的，可以是任意合法的表达式——资源属性、变量引用、函数调用等。在同一个模块内，所有输出值的名称必须唯一。

::: info
Terraform 代码中无法引用本模块内定义的输出值——输出值是给模块调用者或命令行使用的。
:::

### 描述 (description)

与输入变量一样，`description` 向调用者说明输出值的含义：

```hcl
output "instance_ip_addr" {
  value       = aws_instance.server.private_ip
  description = "The private IP address of the main server instance."
}
```

::: tip
描述应站在**使用者**的角度编写——它是面向模块调用者的 API 文档。
:::

### 断言 (precondition)

自 Terraform v1.2.0 起，`output` 块支持 `precondition` 块。与 `variable` 的 `validation` 类似，`precondition` 确保输出值满足某种约束。Terraform 在计算 `value` 表达式**之前**执行 `precondition` 检查，可以防止不合法的值被写入状态文件：

```hcl
output "api_endpoint" {
  value = "https://${aws_instance.web.public_ip}:8443/"

  precondition {
    condition     = aws_instance.web.public_ip != ""
    error_message = "Web 实例没有分配公网 IP 地址。"
  }
}
```

### 在命令行输出中隐藏值 (sensitive)

将 `sensitive` 设为 `true` 后，`terraform apply` 成功后会打印 `<sensitive>` 代替真实值；`terraform output` 列出所有输出时也会显示 `<sensitive>`，但指定输出名称（如 `terraform output db_password`）或使用 `terraform output -json` 时仍可看到实际值：

```hcl
output "db_password" {
  value     = aws_db_instance.main.password
  sensitive = true
}
```

```
Outputs:

db_password = <sensitive>
```

::: warning
`sensitive` 只影响命令行输出。输出值仍然会以明文记录在状态文件中——任何有权限读取状态文件的人都能读取敏感数据。
:::

### 临时值 (ephemeral)

自 Terraform v1.10 起，可以在**子模块**中将 `output` 标记为 `ephemeral`。临时输出的值在 `plan` 和 `apply` 期间可用，但**不会被记录到状态文件和计划文件中**，适合传递凭据、令牌等短生命周期数据：

```hcl
# modules/db/main.tf
output "secret_id" {
  value       = aws_secretsmanager_secret.example.id
  description = "Temporary secret ID for accessing database."
  ephemeral   = true
}
```

临时输出只能在以下上下文中被引用：

- 另一个临时输出值
- 临时输入变量
- 临时资源（ephemeral resource）

::: warning
根模块中**不可以**将 `output` 声明为 `ephemeral`。
:::

### depends_on

一般来说，Terraform 会自动分析资源之间的依赖关系来决定创建顺序。但有时某些依赖关系无法通过代码分析得出，这时可以通过 `depends_on` 显式声明：

```hcl
output "instance_ip_addr" {
  value       = aws_instance.server.private_ip
  description = "The private IP address of the main server instance."

  depends_on = [
    # Security group rule must be created before this IP address could
    # actually be used, otherwise the services will be unreachable.
    aws_security_group_rule.local_access,
  ]
}
```

::: warning
`output` 很少需要 `depends_on`，它只应作为最后的手段使用。如果不得不使用，请务必通过注释说明原因，方便后人维护。
:::

### 🧪 动手实验

<KillercodaEmbed src="https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-syntax-output" />

---

## 局部值 (local)

我们在介绍输入变量时提到过，如果我们把一组 Terraform 代码想象成一个函数，那么输入变量就是函数的入参；函数可以有入参，也可以有返回值——输出值就是 Terraform 代码的返回值。那么局部值就相当于函数内部定义的**局部变量**。

有时我们需要用一个比较复杂的表达式计算某个值，并且在多处反复使用。这时可以把这个复杂表达式赋予一个局部值，然后反复引用该局部值——避免重复，也让代码更易读、更易维护。

### locals 块

局部值通过 `locals` 块定义：

```hcl
locals {
  project     = "my-app"
  environment = "dev"
}
```

一个 `locals` 块可以定义多个局部值。一个模块中也可以定义任意多个 `locals` 块——你可以按逻辑将局部值分组到不同的 `locals` 块中：

```hcl
# 项目信息
locals {
  project     = "my-app"
  environment = "dev"
}

# 计算值
locals {
  full_name = "${local.project}-${local.environment}"
  is_prod   = local.environment == "prod"
}
```

### 引用局部值

在代码中通过 `local.<NAME>` 引用局部值：

```hcl
locals {
  project = "my-app"
}

output "project_name" {
  value = local.project
}
```

::: warning 注意 locals vs local
定义时使用 `locals`（复数），引用时使用 `local`（单数）。这是一个常见的混淆点——定义块是 `locals {}`，但引用表达式是 `local.<NAME>`。
:::

局部值只能在**同一模块**内的代码中引用。

### 表达式计算

赋给局部值的不仅可以是简单的字面量，还可以是更复杂的表达式——引用其他资源的属性、输入变量、数据源，甚至是其他的局部值：

```hcl
variable "project" {
  type    = string
  default = "demo"
}

variable "environment" {
  type    = string
  default = "dev"
}

locals {
  # 引用输入变量
  full_name = "${var.project}-${var.environment}"

  # 引用其他局部值
  is_prod     = var.environment == "prod"
  log_level   = local.is_prod ? "warn" : "debug"

  # 使用函数和复杂表达式
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
```

### 使用场景

局部值最适合在以下场景中使用：

**1. 避免重复复杂表达式**

当同一个表达式在多个地方使用时，用局部值提取它：

```hcl
locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket" "data" {
  bucket = "data-bucket"
  tags   = local.common_tags
}

resource "aws_s3_bucket" "logs" {
  bucket = "logs-bucket"
  tags   = local.common_tags
}
```

**2. 给复杂表达式起一个有意义的名字**

局部值可以充当"命名表达式"，提高可读性：

```hcl
locals {
  is_production    = var.environment == "prod"
  needs_encryption = local.is_production || var.force_encryption
  instance_type    = local.is_production ? "m5.large" : "t3.micro"
}
```

**3. 预处理输入数据**

```hcl
variable "raw_cidrs" {
  type    = list(string)
  default = ["10.0.0.0/8", " 172.16.0.0/12 ", "192.168.0.0/16"]
}

locals {
  # 去除每个 CIDR 的前后空格
  clean_cidrs = [for cidr in var.raw_cidrs : trimspace(cidr)]
}
```

::: tip 适度使用
局部值可以帮助我们避免重复复杂的表达式，提升代码的可读性。但如果过度使用也有可能增加代码的复杂度——使得维护者需要在多个 `locals` 块之间跳转才能理解一个值的来源。

适度使用局部值，仅用于反复引用同一复杂表达式的场景。当我们需要修改该表达式时，局部值将使得修改变得相当轻松。
:::

### 临时局部值 (ephemeral)

自 Terraform v1.10 起，如果局部值的表达式中引用了**临时值**（如 `ephemeral = true` 的输入变量），则该局部值会**隐式**地成为临时值：

```hcl
variable "service_token" {
  type      = string
  ephemeral = true
}

locals {
  session_token = "Bearer ${var.service_token}"
}
```

`local.session_token` 隐式成为临时值，因为它依赖于临时输入变量 `var.service_token`。临时局部值不会被记录到状态文件和计划文件中，与其他临时值有相同的引用限制。

### 🧪 动手实验

<KillercodaEmbed src="https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-syntax-local" />

---

## 资源 (resource)

资源是 Terraform 最重要的组成部分。资源通过 `resource` 块来定义，一个 `resource` 可以定义一个或多个基础设施资源对象，例如 VPC、虚拟机，或是 DNS 记录、S3 存储桶等。

### resource 块

资源通过 `resource` 块定义。紧跟 `resource` 关键字的第一个标签是**资源类型**，第二个标签是资源的**本地名称**（Local Name）：

```hcl
resource "aws_instance" "web" {
  ami           = "ami-a1b2c3d4"
  instance_type = "t2.micro"
}
```

- **资源类型**（如 `aws_instance`）决定了被管理的基础设施对象的种类，以及该资源支持哪些参数和输出属性。资源类型名的第一个单词（下划线前）通常对应 Provider 名称——`aws_instance` 由 `aws` Provider 提供。
- **本地名称**（如 `web`）用于在同一模块内引用该资源。类型 + 本地名称的组合在模块内必须唯一。
- 花括号内的**块体**包含资源的参数赋值，不同资源类型有不同的可用参数，可查阅 Provider 文档了解。

::: info 声明式语言
Terraform 是声明式语言——描述的是期望的资源状态，而不是达到该状态的步骤。块的顺序和所在文件通常不重要，Terraform 根据资源间的依赖关系自动决定操作顺序。
:::

### 资源的行为

对 Terraform 代码执行 `terraform apply` 时，Terraform 会：

1. **创建**（`+`）代码中定义但状态文件中不存在的资源
2. **更新**（`~`）状态文件中已有但与代码定义不一致的资源
3. **替换**（`-/+`）某些属性变更导致资源必须重建
4. **销毁**（`-`）状态文件中存在但代码中已删除的资源

每当 Terraform 创建一个新资源，该资源的 ID 会被保存到状态文件中，使得后续可以对它进行更新或销毁。

#### 就地更新 vs 替换（ForceNew）

当修改资源的某个参数时，Terraform 会根据该参数的性质决定操作方式：

- **就地更新**（update in-place，`~`）— 大部分参数可以在不销毁资源的情况下直接修改。例如修改 S3 桶的标签、修改 SQS 队列的 `visibility_timeout_seconds` 等。
- **替换**（replacement，`-/+`）— 某些参数被 Provider 标记为 **ForceNew**，意味着该参数的变更无法通过 API 就地修改，只能销毁旧资源、创建新资源。例如 SQS 队列的 `name`、EC2 实例的 `ami`、S3 桶的 `bucket` 名称等。

ForceNew 是由底层云 API 的限制决定的——有些属性在资源创建后就不可变（immutable），想要改变只能重新创建。Provider 文档中通常会标注哪些参数是 ForceNew 的。

`terraform plan` 中会用 `# forces replacement` 注释标明是哪个参数触发了替换：

```
-/+ resource "aws_sqs_queue" "example" {
      ~ name = "old-name" -> "new-name" # forces replacement
    }
```

#### `-/+` 与 `+/-`

替换操作有两种顺序：

- **`-/+`**（先删后建）— 默认行为。Terraform 先销毁旧资源，再创建新资源。在两步之间资源不可用。
- **`+/-`**（先建后删）— 当资源配置了 `create_before_destroy = true` 时，Terraform 先创建新资源，确认成功后再销毁旧资源。这可以减少服务中断时间。

`terraform plan` 的输出中会用 `-/+` 或 `+/-` 前缀来区分这两种替换顺序。

### 访问资源属性

资源创建后会输出一些只读**属性**（Attribute），通常包含创建前无法预知的数据（如资源 ID、ARN 等）。在同一模块内通过 `<资源类型>.<名称>.<属性>` 引用：

```hcl
resource "aws_s3_bucket" "data" {
  bucket = "my-data-bucket"
}

# 引用 S3 桶的 ARN 属性
output "bucket_arn" {
  value = aws_s3_bucket.data.arn
}

# 在其他资源中引用
resource "aws_s3_object" "readme" {
  bucket  = aws_s3_bucket.data.id
  key     = "readme.txt"
  content = "Hello from Terraform!"
}
```

::: tip
要了解某个资源类型的所有可用属性，查阅对应 Provider 的文档。文档中通常会分别列出参数（Argument）和属性（Attribute）。
:::

### 资源的依赖关系

大部分情况下，Terraform 会通过分析表达式中的引用链自动推导资源间的依赖关系。例如上面的 `aws_s3_object.readme` 引用了 `aws_s3_bucket.data.id`，Terraform 会自动确保先创建桶再创建对象。

但有时依赖关系无法从代码中推导出来——例如某个资源运行时需要另一个权限资源已经存在，但代码中并没有直接引用。这种场景需要用 `depends_on` 显式声明（见下文元参数部分）。

### 元参数 (Meta-Arguments)

`resource` 块支持一组特殊的**元参数**，它们可以用在所有资源类型上，改变资源的行为：

| 元参数 | 用途 |
|--------|------|
| `depends_on` | 显式声明依赖关系 |
| `count` | 创建多个资源实例 |
| `for_each` | 迭代集合，为每个元素创建资源实例 |
| `provider` | 指定非默认 Provider 实例 |
| `lifecycle` | 自定义资源的生命周期行为 |

#### depends_on

`depends_on` 用于显式声明 Terraform 无法自动推导的隐含依赖关系：

```hcl
resource "aws_iam_role" "example" {
  name               = "example"
  assume_role_policy = "..."
}

resource "aws_iam_role_policy" "s3_access" {
  name   = "s3-access"
  role   = aws_iam_role.example.name
  policy = jsonencode({
    Statement = [{
      Action = "s3:*"
      Effect = "Allow"
    }]
  })
}

resource "aws_instance" "app" {
  ami           = "ami-a1b2c3d4"
  instance_type = "t2.micro"

  # 代码中没有直接引用 s3_access，但运行时需要该权限，depends_on 可以确保只有当 s3 的权限配置完成后才会尝试创建虚拟机
  depends_on = [
    aws_iam_role_policy.s3_access,
  ]
}
```

::: warning
`depends_on` 只应作为最后的手段使用。如果不得不使用，请通过注释说明原因，方便后人维护。
:::

#### count

`count` 参数用于从单个 `resource` 块创建多个相似的资源实例：

```hcl
resource "aws_s3_bucket" "logs" {
  count  = 3
  bucket = "app-logs-${count.index}"
}
```

`count.index` 是当前实例的索引号（从 0 开始）。声明了 `count` 的资源通过下标访问：

```hcl
# 访问第一个桶
output "first_bucket" {
  value = aws_s3_bucket.logs[0].id
}

# 获取所有桶的 ID
output "all_bucket_ids" {
  value = aws_s3_bucket.logs[*].id
}
```

::: warning count 的陷阱
`count` 使用数字索引标识资源。如果从列表中间删除一个元素，后续所有资源的索引都会移位，导致大量不必要的更新或重建。对于这类场景，推荐使用 `for_each`。
:::

#### for_each

`for_each` 参数接受一个 `map` 或 `set(string)`，为集合中的每个元素创建一个资源实例：

```hcl
# 使用 map
resource "aws_s3_bucket" "this" {
  for_each = {
    data = "my-data-bucket"
    logs = "my-logs-bucket"
  }

  bucket = each.value
  tags = {
    Name = each.key
  }
}
```

在 `for_each` 块内通过 `each` 对象访问当前元素：

- `each.key` — map 的键，或 set 中的值
- `each.value` — map 的值，或 set 中的值

声明了 `for_each` 的资源通过键访问：

```hcl
output "data_bucket_id" {
  value = aws_s3_bucket.this["data"].id
}
```

使用 `set(string)` 时，需要用 `toset` 转换：

```hcl
resource "aws_sqs_queue" "this" {
  for_each = toset(["orders", "notifications", "events"])
  name     = "${each.key}-queue"
}
```

#### count 与 for_each 的选择

- 资源实例**几乎完全一致**（只差一个序号）→ `count`
- 资源实例**各有差异**，或需要稳定标识 → `for_each`

`for_each` 使用键而非数字索引标识资源，删除集合中的某个元素只会影响对应的那一个资源实例，不会引起其他实例的变更。

::: info count 和 for_each 不可同时使用
一个 `resource` 块中不允许同时声明 `count` 和 `for_each`。
:::

#### provider

当声明了同一类型 Provider 的多个实例（使用 `alias`）时，可以通过 `provider` 元参数指定资源使用哪个实例：

```hcl
provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "west"
  region = "us-west-2"
}

resource "aws_s3_bucket" "west_bucket" {
  provider = aws.west
  bucket   = "my-west-bucket"
}
```

未指定 `provider` 时，Terraform 默认使用资源类型名第一个单词对应的默认 Provider 实例。

#### lifecycle

`lifecycle` 块用于自定义资源的生命周期行为，嵌套在 `resource` 块内：

```hcl
resource "aws_s3_bucket" "important" {
  bucket = "critical-data-bucket"

  lifecycle {
    prevent_destroy = true
  }
}
```

`lifecycle` 支持以下参数：

**`create_before_destroy`** — 当资源因 ForceNew 参数变更需要被替换时，先创建新资源，再销毁旧资源（默认是先删后建）：

```hcl
lifecycle {
  create_before_destroy = true
}
```

这在需要保持服务可用性的场景下非常有用——确保新资源就绪后再删除旧资源，避免服务中断。配置后，`terraform plan` 的替换操作会显示为 `+/-`（而非默认的 `-/+`）。

**`prevent_destroy`** — 阻止 Terraform 销毁该资源。如果执行计划包含销毁操作，Terraform 会报错并中止：

```hcl
lifecycle {
  prevent_destroy = true
}
```

这是一种安全机制，适用于数据库、存储桶等不应被意外删除的资源。但它有两个重要限制：

1. `prevent_destroy` 只在 `resource` 块存在时生效——如果直接删除整个 `resource` 块，Terraform 不会阻止销毁
2. 由于 `lifecycle` 不支持变量，`prevent_destroy` 的值只能硬编码为 `true` 或 `false`，无法根据环境动态切换（参见前文 [lifecycle 不支持动态表达式](#lifecycle) 的说明）

因此在实际项目中 `prevent_destroy` 的使用并不多见——它在开发阶段会阻碍 `terraform destroy` 清理资源，而切换环境时又无法通过变量控制。

**`ignore_changes`** — 忽略指定属性的变更。当某些属性在资源创建后会被外部系统修改时，这可以防止 Terraform 覆盖这些变更：

```hcl
resource "aws_instance" "web" {
  ami           = "ami-a1b2c3d4"
  instance_type = "t2.micro"

  lifecycle {
    ignore_changes = [
      tags,          # 忽略 tags 的变化
    ]
  }
}
```

使用 `ignore_changes = all` 可以忽略所有属性的变更——资源创建后 Terraform 不再管理它。

**`replace_triggered_by`** — 当指定的引用发生变化时，强制替换该资源：

```hcl
resource "aws_instance" "web" {
  # ...

  lifecycle {
    replace_triggered_by = [
      null_resource.always_replace  # 当这个资源变化时，替换 web 实例
    ]
  }
}
```

::: warning lifecycle 不支持动态表达式
`lifecycle` 块中的参数值必须是**字面量**，不能使用变量（`var.xxx`）、局部值（`local.xxx`）、资源属性或任何其他引用和表达式。例如：

```hcl
# ❌ 不合法！lifecycle 参数不能引用变量
variable "is_prod" {
  type    = bool
  default = true
}

resource "aws_s3_bucket" "data" {
  bucket = "my-bucket"

  lifecycle {
    prevent_destroy = var.is_prod  # Error: Variables not allowed
  }
}
```

这是 Terraform 的一个已知限制——`lifecycle` 块在表达式求值之前就需要被解析，因此无法依赖运行时才确定的值。社区对此有长期的讨论（参见 [hashicorp/terraform#25534](https://github.com/hashicorp/terraform/issues/25534)），但截至目前该限制仍未解除。
:::

### Precondition 与 Postcondition

自 Terraform v1.2 起，`resource` 块支持 `precondition` 和 `postcondition` 块，用于在创建/更新资源前后进行自定义断言：

```hcl
resource "aws_s3_bucket" "data" {
  bucket = var.bucket_name

  # 创建前检查
  lifecycle {
    precondition {
      condition     = length(var.bucket_name) >= 3
      error_message = "桶名长度必须至少 3 个字符。"
    }

    postcondition {
      condition     = self.arn != ""
      error_message = "桶创建后未返回 ARN。"
    }
  }
}
```

- **`precondition`** — 在 Terraform 计算资源配置之前执行，可以引用输入变量和其他已知值
- **`postcondition`** — 在资源创建/更新之后执行，可以通过 `self` 引用当前资源的属性

### Provisioner

`provisioner` 块用于在资源创建或销毁时执行额外操作（如运行脚本）。Provisioner 是 Terraform 的"逃生舱"——当 Provider 不支持某些操作时的最后手段：

```hcl
resource "aws_instance" "web" {
  ami           = "ami-a1b2c3d4"
  instance_type = "t2.micro"

  # 创建时执行
  provisioner "local-exec" {
    command = "echo ${self.private_ip} >> ip_list.txt"
  }

  # 销毁时执行
  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Instance destroyed' >> ip_list.txt"
  }
}
```

常用的 provisioner 类型：

- **`local-exec`** — 在运行 Terraform 的机器上执行命令
- **`remote-exec`** — 通过 SSH 或 WinRM 在远程资源上执行命令（需配合 `connection` 块）
- **`file`** — 将文件或目录复制到远程资源

在 provisioner 块内不能通过父资源名称引用自身，必须使用特殊的 `self` 对象。例如 `self.private_ip` 而非 `aws_instance.web.private_ip`，因为按名称引用会产生循环依赖。

::: warning 慎用 Provisioner
Terraform 官方建议尽量避免使用 provisioner，因为：
1. Provisioner 不会被记录在状态文件中，Terraform 无法跟踪其执行状态
2. 如果 provisioner 失败，资源会被标记为"受损"（tainted）
3. 大多数场景可以通过 Provider 原生功能、`cloud-init`、配置管理工具等更好地实现

`local-exec` provisioner 相对安全，常用于触发外部操作（如通知、记录等）。
:::

#### when — 控制执行时机

`when` 参数控制 provisioner 在什么时候执行。默认值为创建时执行，设为 `destroy` 则在资源销毁时执行：

```hcl
resource "aws_instance" "web" {
  # ...

  # 创建时执行（默认行为，可省略 when）
  provisioner "local-exec" {
    command = "echo 'Created ${self.id}' >> deploy.log"
  }

  # 销毁时执行
  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Destroying ${self.id}' >> deploy.log"
  }
}
```

**创建时预置器**（Creation-time provisioner）——如果失败，Terraform 会将资源标记为受损（tainted），下次 `apply` 时会销毁并重新创建该资源。这是因为失败的 provisioner 可能导致资源处于半配置状态，重建是唯一可靠的恢复方式。

**销毁时预置器**（Destroy-time provisioner）——在资源被销毁**之前**执行。如果失败，Terraform 会报错并在下次 `apply` 时重新尝试。需要注意：

- 销毁时预置器必须确保可以**安全地多次执行**（幂等性）
- 如果资源配置了 `create_before_destroy = true`，销毁时预置器**不会执行**
- 如果直接从配置中删除整个 `resource` 块，销毁时预置器也**不会执行**——因为 provisioner 配置随资源块一起消失了

::: tip 安全删除带销毁时预置器的资源
如果资源包含销毁时预置器，不要直接删除 `resource` 块。应分两步操作：
1. 先设置 `count = 0`，执行 `apply` 销毁资源（此时销毁时预置器会正常执行）
2. 再从配置中删除整个 `resource` 块
:::

#### on_failure — 失败行为

默认情况下，provisioner 失败会导致 `terraform apply` 失败。可以通过 `on_failure` 参数改变行为：

```hcl
provisioner "local-exec" {
  command    = "echo 'setup complete'"
  on_failure = continue   # 失败时继续，不中止 apply
}
```

- `on_failure = fail`（默认）— provisioner 失败时中止操作，资源被标记为受损
- `on_failure = continue` — 忽略错误，继续后续操作

#### 多个 provisioner

一个资源可以包含多个 provisioner 块，Terraform 按定义顺序依次执行。可以在同一资源中混合使用创建时和销毁时预置器——Terraform 只会在对应的阶段执行相应的预置器。

#### 无资源的 provisioner

如果需要运行不与特定资源关联的 provisioner，可以搭配 `terraform_data` 资源使用：

```hcl
resource "terraform_data" "notify" {
  triggers_replace = [aws_instance.web.id]

  provisioner "local-exec" {
    command = "notify-team.sh 'Instance ${aws_instance.web.id} deployed'"
  }
}
```

`terraform_data` 不管理真实的基础设施对象，但支持完整的资源生命周期，可以通过 `triggers_replace` 控制何时重新执行 provisioner。

### dynamic 块

在编写资源配置时，有时需要根据变量动态生成重复的嵌套块。`dynamic` 块提供了这种能力：

```hcl
variable "ingress_rules" {
  type = list(object({
    port        = number
    description = string
  }))
  default = [
    { port = 80,  description = "HTTP" },
    { port = 443, description = "HTTPS" },
    { port = 8080, description = "Alt HTTP" },
  ]
}

resource "aws_security_group" "web" {
  name = "web-sg"

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = ingress.value.description
    }
  }
}
```

`dynamic` 块的工作方式：

1. **标签**（`"ingress"`）对应要生成的嵌套块类型
2. **`for_each`** — 要遍历的集合
3. **`content`** — 嵌套块的内容模板
4. 在 `content` 内通过 `<标签>.value` 访问当前元素（类似 `each.value`）

可以通过 `iterator` 参数自定义迭代器变量名：

```hcl
dynamic "ingress" {
  for_each = var.ingress_rules
  iterator = rule        # 使用 rule 代替默认的 ingress
  content {
    from_port = rule.value.port
    to_port   = rule.value.port
    protocol  = "tcp"
  }
}
```

::: warning 适度使用
`dynamic` 块虽然强大，但过度使用会严重降低代码可读性。Terraform 官方建议只在需要根据变量动态生成嵌套块时使用——如果嵌套块的数量和内容是固定的，直接写出来更清晰。
:::

### 删除资源

有三种方式从 Terraform 管理中移除资源：

1. **删除 `resource` 块并执行 `apply`** — Terraform 会销毁对应的实际资源
2. **`terraform state rm`** — 仅从状态文件中移除记录，不销毁实际资源（"解除管理"）
3. **`removed` 块**（Terraform v1.7+）— 在代码中声明某个资源不再受管理：

```hcl
removed {
  from = aws_instance.old_server

  lifecycle {
    destroy = false   # 不销毁实际资源，只从状态中移除
  }
}
```

### 操作超时设置

部分资源类型支持 `timeouts` 嵌套块，用于设置创建、更新、删除操作的超时时间：

```hcl
resource "aws_db_instance" "main" {
  # ...

  timeouts {
    create = "60m"
    delete = "2h"
  }
}
```

超时时间的格式是一个数字加单位后缀（`s` 秒、`m` 分钟、`h` 小时）。支持哪些操作取决于具体的资源类型。

### 🧪 动手实验

本节实验分为三个部分，每部分创建一个基于 LocalStack 的仿真应用：

<KillercodaEmbed src="https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-syntax-resource" />

---

## 数据源 (data)

<!-- TODO: data 块、查询已有资源、与 resource 的区别 -->

---

## 重载文件

<!-- TODO: override files 的作用和使用场景 -->

---

## Checks

<!-- TODO: check 块、assert、precondition/postcondition -->
