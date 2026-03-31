---
order: 2
title: 基础：Terraform 基本生命周期
---

# 基础：Terraform 基本生命周期

在这一章中，你将通过一台 EC2 虚拟机，学习 Terraform 管理基础设施的完整生命周期——**创建、验证幂等性、修改配置、销毁资源**。

## 📝 核心概念

### 编写配置

Terraform 使用 `.tf` 文件描述基础设施。以下是本实验的配置文件，它定义了一台 EC2 实例：

```hcl
resource "aws_instance" "tutorial" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  tags = {
    Name = "TerraformTutorial"
  }
}
```

- `resource` 块声明一个要管理的资源，`"aws_instance"` 是资源类型，`"tutorial"` 是本地名称
- `ami` 指定虚拟机镜像，`instance_type` 指定机器规格
- `tags` 为实例添加元数据标签

### Terraform 的核心命令

| 命令 | 作用 |
|------|------|
| `terraform init` | 初始化工作目录，下载 Provider 插件 |
| `terraform plan` | 预览即将执行的变更（干跑模式） |
| `terraform apply` | 执行变更，创建/修改资源 |
| `terraform destroy` | 销毁所有 Terraform 管理的资源 |

### 创建资源

运行 `terraform init` 初始化项目后，`terraform apply` 会创建配置中声明的资源。Terraform 会输出执行计划并等待确认（加 `-auto-approve` 可跳过确认）。

### 幂等性

Terraform 是**幂等**的——如果基础设施已经处于配置文件描述的期望状态，重复执行 `terraform apply` 不会产生任何变更：

```text
No changes. Your infrastructure matches the configuration.
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
```

这意味着你可以放心地多次执行 apply，Terraform 只在需要时才会采取行动。

### 修改资源

当你修改 `.tf` 文件（例如将 `instance_type` 从 `t2.micro` 改为 `t2.small`）后执行 `plan`，Terraform 会输出变更预览：

- `+` 表示**将要创建**的资源
- `-` 表示**将要销毁**的资源
- `~` 表示**将要就地修改**的资源（如更改实例类型）
- `-/+` 表示**需要先销毁再重建**的资源（如更换 AMI）

::: tip 最佳实践
在生产环境中，务必先 `plan` 审查输出，确认无误后再 `apply`。`plan` 是你的安全网。
:::

### 销毁资源

`terraform destroy` 会销毁 Terraform 管理的所有资源。建议先执行 `terraform plan -destroy` 预览将要销毁的资源，确认无误后再执行。

### 使用 awslocal 验证

`awslocal` 是 [LocalStack 提供的 AWS CLI 封装工具](https://docs.localstack.cloud/user-guide/integrations/aws-cli/#localstack-aws-cli-awslocal)，自动将请求指向本地的 LocalStack 端点（`http://localhost:4566`），省去每次手动指定 `--endpoint-url` 的麻烦：

```bash
# 等价于 aws --endpoint-url=http://localhost:4566 ec2 describe-instances
awslocal ec2 describe-instances \
  --query "Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name]" \
  --output table
```

在本教程中，每一步操作后我们都会使用 `awslocal` 来独立验证 Terraform 的变更是否真正生效。

## 🧪 动手实验

在下面的沙盒中，你将完成 EC2 实例的完整生命周期管理：

1. **创建** — `terraform init` + `terraform apply` 创建一台 `t2.micro` 实例，用 `awslocal` 确认
2. **幂等性验证** — 重复执行 `terraform apply`，确认输出 `0 changed`，用 `awslocal` 确认无变化
3. **修改配置** — 将实例类型改为 `t2.small`，`plan` 查看差异，`apply` 并用 `awslocal` 确认变更
4. **销毁** — `terraform destroy` 清理所有资源，用 `awslocal` 确认实例已消失

<KillercodaEmbed src="https://killercoda.com/lonegunman/course/terraform-tutorial/terraform-basics~embed" />

::: info 关于实验环境
沙盒已预装 Terraform CLI、AWS CLI、awslocal 和 LocalStack（模拟 EC2）。工作目录中有一份预置的 `main.tf`，配置了 LocalStack 的 Endpoint 和伪 AWS 凭证，无需真实 AWS 账号。
:::
