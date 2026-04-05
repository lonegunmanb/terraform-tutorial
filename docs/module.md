---
order: 5
title: Terraform 模块
---

# Terraform 模块

Terraform 模块（Module）是 Terraform 配置的逻辑封装单元，是实现代码复用、团队协作和基础设施标准化的核心机制。

本章将系统介绍模块的概念与实践，涵盖以下内容：

## 目录

- [何为 module](#何为-module) — 模块的概念与作用
- [创建 module](#创建-module) — 编写可复用的模块
- [使用 module](#使用-module) — 在配置中引用模块
- [module 元参数](#module-元参数) — count、for_each、providers、depends_on
- [重构](#重构) — 使用 moved 块安全地重构模块

---

## 何为 module

模块（Module）是 Terraform 中**最核心的代码组织单元**。简单来说，一个包含 `.tf` 文件的目录就是一个模块。

你在前面所有章节中编写的代码——放在 `/root/workspace/step*` 目录下的那些 `.tf` 文件——本身就构成了一个模块，叫做 **根模块**（Root Module）。当你执行 `terraform plan` 或 `terraform apply` 时，Terraform 从当前工作目录加载所有 `.tf` 文件，这个目录就是根模块。

### 根模块（Root Module）

每次执行 Terraform 命令时，当前工作目录就是根模块。根模块是整个配置的入口点。Terraform 的执行总是从根模块开始。

你之前写过的所有代码——provider 配置、resource 声明、variable 和 output 定义——都属于根模块的内容。即使你没有刻意"创建模块"，你其实一直在使用模块：

```
/root/workspace/          ← 这就是根模块
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

## 创建 module

TODO

---

## 使用 module

TODO

---

## module 元参数

TODO

---

## 重构

TODO
