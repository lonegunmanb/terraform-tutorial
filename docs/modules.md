---
order: 5
title: 模块化实践
---

# 模块化实践

模块是 Terraform 配置的可复用容器。通过模块化，你可以避免代码重复，提升基础设施代码的可维护性和一致性。

## 📝 核心概念

### 什么是模块？

一个模块就是一个包含 `.tf` 文件的目录。实际上，你一直在使用模块 —— 你的项目根目录就是**根模块 (Root Module)**。

```
project/
├── main.tf          ← 根模块
├── variables.tf
├── outputs.tf
└── modules/
    └── s3-bucket/   ← 子模块
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

### 调用模块

```hcl
module "logs_bucket" {
  source = "./modules/s3-bucket"

  bucket_name = "my-app-logs"
  environment = "production"
}
```

### 模块的三要素

| 文件 | 作用 |
|------|------|
| `variables.tf` | 定义模块的输入参数 |
| `main.tf` | 核心资源定义 |
| `outputs.tf` | 暴露模块的输出值供调用方使用 |

::: tip 模块设计原则
- 单一职责：一个模块只做一件事
- 合理暴露变量：让调用方能定制，但不要暴露过多细节
- 为每个变量写 `description` 和合理的 `default`
- 使用 `validation` 块对输入做约束
:::

### 使用远程模块

除了本地模块，还可以引用 Terraform Registry 或 Git 仓库中的模块：

```hcl
# 来自 Terraform Registry
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.0"
  # ...
}

# 来自 Git
module "custom" {
  source = "git::https://github.com/org/modules.git//network?ref=v1.0.0"
}
```

## 🧪 动手实验

在下面的终端中完成以下操作：

1. 查看 `modules/s3-bucket/` 目录中的模块代码
2. 在根模块中调用该模块创建一个存储桶
3. 运行 `terraform init` 和 `terraform apply`
4. 修改模块参数后重新 `plan`，观察变更

<KillercodaEmbed src="https://killercoda.com/lonegunman/course/killercoda/terraform-modules~embed" />
