---
order: 3
title: 状态管理
---

# 状态管理

Terraform 通过 **状态文件** (`terraform.tfstate`) 追踪已管理资源的当前状态。状态文件是 Terraform 将配置代码与真实基础设施关联的关键桥梁。

## 📝 核心概念

### 状态文件的作用

每次执行 `terraform apply` 后，Terraform 会将所创建资源的属性（ID、ARN、IP 等）写入状态文件。下次执行 `plan` 时，Terraform 对比：

```
期望状态（.tf 代码） ←→ 当前状态（.tfstate 文件）
```

差异部分就是需要执行的变更。

### 常用状态命令

| 命令 | 作用 |
|------|------|
| `terraform state list` | 列出所有已管理的资源 |
| `terraform state show <resource>` | 查看单个资源的详细属性 |
| `terraform state mv` | 重命名或移动资源（不销毁重建） |
| `terraform state rm` | 从状态中移除资源（不销毁真实资源） |

::: warning 注意
状态文件可能包含敏感信息（如数据库密码）。在团队协作中，应使用远程后端（如 S3 + DynamoDB）存储状态，并启用加密。
:::

### 远程后端

```hcl
terraform {
  backend "s3" {
    bucket         = "my-tf-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-locks"
    encrypt        = true
  }
}
```

## 🧪 动手实验

在下面的终端中完成以下操作：

1. 运行 `terraform state list` 查看已管理的资源
2. 运行 `terraform state show aws_s3_bucket.data` 查看资源详情
3. 查看 `terraform.tfstate` 文件内容
4. 尝试手动修改资源标签后重新 `plan`，观察状态差异

<KillercodaEmbed src="https://killercoda.com/lonegunman/course/killercoda/terraform-state~embed" />
