---
order: 3
title: 状态管理
---

# 状态管理

## 📝 为什么 Terraform 需要状态？

AWS CloudFormation 和 Azure ARM 模板不需要外部状态文件，因为它们与各自的云平台紧密耦合，可以直接依赖平台内部的状态管理。但 Terraform 不同——它的可插拔 Provider 架构使它能够管理任意平台的资源，因此**不能假设任何平台都有内置的状态追踪能力**。

Terraform 的解决方案是维护一个 **状态文件**（`terraform.tfstate`），以统一、一致的方式记录它所创建的每一个资源。

### 状态文件的两大作用

**1. 统一记录已创建的资源**

每次执行 `terraform apply` 后，Terraform 会把创建的资源及其所有属性（ID、ARN、标签等）写入状态文件。下次执行 `plan` 时，Terraform 通过对比三方信息来决定变更计划：

```
代码（.tf 文件）  ←→  状态文件（.tfstate）  ←→  真实环境（Provider 查询）
```

- 如果状态文件为空（Day 1），Terraform 假定一切都需要创建
- 如果状态文件已存在（Day 2），Terraform 会通过 Provider 查询真实环境，对比代码中的期望状态，找出差异并生成变更计划

**2. 划定管理边界——Terraform 只管理它创建的资源**

这个设计可以用一个经典的类比来说明：在《侏罗纪公园》中，公园的监控系统被设计成只追踪已知的恐龙数量。系统始终报告"一切正常"，因为它只寻找自己清单上的恐龙——从未发现意外繁殖出的新恐龙。

Terraform 的状态文件就像这份恐龙清单：**Terraform 只关心状态文件中记录的资源**。如果有人在 Terraform 之外手动创建了一个 S3 存储桶，Terraform 根本不会知道它的存在，也不会去管理它。

这种设计对 Terraform 来说是**优点**而非缺点：
- 团队可以**渐进式采用** Terraform，先管理一部分资源，其余的手动管理
- Terraform 不会意外修改或删除它不负责的资源
- 不同团队可以使用不同的工具管理各自的资源，互不干扰

### 代码 vs 状态文件

代码中的资源定义通常很简洁：

```hcl
resource "aws_s3_bucket" "data" {
  bucket = "my-app-data-bucket"
  tags = {
    Name = "Data Bucket"
  }
}
```

但状态文件中存储的信息**远比代码详细**，包括了资源的所有属性：

```json
{
  "mode": "managed",
  "type": "aws_s3_bucket",
  "name": "data",
  "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
  "instances": [
    {
      "schema_version": 0,
      "attributes": {
        "id": "my-app-data-bucket",
        "bucket": "my-app-data-bucket",
        "arn": "arn:aws:s3:::my-app-data-bucket",
        "tags": { "Name": "Data Bucket" },
        "tags_all": { "Name": "Data Bucket" }
      }
    }
  ]
}
```

### 漂移检测（Drift Detection）

如果有人绕过 Terraform 直接修改了资源（比如在 AWS 控制台手动添加了一个标签），就会产生**漂移**（Drift）——真实环境与 Terraform 状态文件中的记录不一致。

当你再次运行 `terraform plan` 时，Terraform 会通过 Provider 查询真实环境的当前状态，与代码和状态文件对比，发现这种漂移，并生成计划将环境恢复到代码描述的期望状态。

### 常用状态命令

| 命令 | 作用 |
|------|------|
| `terraform state list` | 列出所有已管理的资源 |
| `terraform state show <resource>` | 查看单个资源的详细属性 |

::: warning 注意
状态文件可能包含敏感信息（如数据库密码、访问密钥等）。不要将 `terraform.tfstate` 提交到版本控制系统中。
:::

## 🧪 动手实验

在下面的实验环境中，你将亲手体验上述概念：

1. **探索状态文件** — 查看代码与状态文件的差异，理解状态文件的结构
2. **漂移检测** — 在 Terraform 之外修改资源，观察 Terraform 如何发现并修复漂移
3. **删除资源** — 删除代码中的资源定义，理解为什么状态文件是不可或缺的

<KillercodaEmbed src="https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-state" />
