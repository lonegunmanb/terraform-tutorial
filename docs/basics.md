---
order: 2
title: 基础：Init / Plan / Apply
---

# 基础：Init / Plan / Apply

Terraform 的工作流围绕三个核心命令展开：

| 命令 | 作用 |
|------|------|
| `terraform init` | 初始化工作目录，下载 Provider 插件 |
| `terraform plan` | 预览即将执行的变更（干跑模式） |
| `terraform apply` | 执行变更，创建/修改/销毁资源 |

## 📝 核心概念

### 1. 初始化 (init)

`terraform init` 是每个 Terraform 项目的第一步。它会：

- 读取 `required_providers` 声明
- 从 Terraform Registry 下载 Provider 插件
- 在 `.terraform/` 目录中缓存插件
- 生成 `.terraform.lock.hcl` 锁定文件

### 2. 计划 (plan)

`terraform plan` 对比**期望状态**（你的 `.tf` 代码）和**当前状态**（状态文件），输出变更预览：

- `+` 表示**将要创建**的资源
- `-` 表示**将要销毁**的资源
- `~` 表示**将要修改**的资源

::: tip 最佳实践
在生产环境中，务必先 `plan` 审查输出，确认无误后再 `apply`。
:::

### 3. 应用 (apply)

`terraform apply` 执行变更并更新状态文件。加上 `-auto-approve` 可跳过交互式确认。

## 🧪 动手实验

在下面的终端中完成以下操作：

1. 运行 `terraform init` 初始化项目
2. 运行 `terraform plan` 查看变更预览
3. 运行 `terraform apply -auto-approve` 创建 S3 存储桶
4. 运行 `aws --endpoint-url=http://localhost:4566 s3 ls` 验证结果

<KillercodaEmbed src="https://killercoda.com/lonegunman/course/terraform-tutorial/terraform-basics~embed" />

::: info 关于实验环境
沙盒已预装 Terraform CLI、TFLint 和 LocalStack。工作目录中有一份预置的 `main.tf`，配置了 LocalStack 的 Endpoint 和伪 AWS 凭证。
:::
