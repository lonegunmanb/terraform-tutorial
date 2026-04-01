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

### 块（Block）

块是 HCL 配置的基本结构单元。每个块由**块类型**、零个或多个**标签**和一个**块体**组成：

```hcl
块类型 "标签1" "标签2" {
  # 块体：包含参数和嵌套块
}
```

不同的块类型有不同数量的标签：

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

### 参数（Argument）

参数是块体内的 `名称 = 值` 赋值语句。等号左侧是参数名（标识符），右侧是参数值：

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
greeting = "Hello, ${var.name}!"
full_name = "${local.project}-${local.environment}"
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

<KillercodaEmbed src="https://killercoda.com/lonegunman/course/terraform-tutorial/terraform-syntax" />

---

## 类型

<!-- TODO: string, number, bool, list, map, set, object, tuple -->

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
