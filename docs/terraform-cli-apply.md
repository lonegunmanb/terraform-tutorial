---
order: 93
title: apply
group: Terraform CLI
group_order: 9
---

# terraform apply

`terraform apply` 执行 Terraform 执行计划，对基础设施进行实际变更。它可以先自动生成计划再应用，也可以直接执行一份已保存的计划文件。

## 用法

```bash
terraform apply [options] [plan file]
```

## 运行模式

### 自动规划模式

不传计划文件时，`terraform apply` 的行为等同于先运行 `terraform plan`，然后等待你在终端输入 `yes` 确认：

```bash
terraform apply
```

Terraform 会先输出完整的执行计划，然后显示确认提示：

```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value:
```

输入 `yes` 并回车后，Terraform 开始执行变更，并实时打印每个资源的进度：

```
aws_s3_bucket.app: Creating...
aws_s3_bucket.app: Creation complete after 1s [id=myapp-dev-app-lab]
```

全部操作完成后打印汇总行：

```
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

在此模式下，可以使用 `terraform plan` 支持的所有[规划模式与规划选项](/terraform-cli-plan#规划模式)。

### 保存计划模式

传入由 `terraform plan -out` 生成的计划文件时，Terraform 直接执行该计划，**不再提示确认**：

```bash
terraform apply tfplan
```

传入计划文件本身就代表已审批，Terraform 不会再询问 `yes/no`。此模式是 CI/CD 两步工作流的核心：

| 阶段 | 命令 | 说明 |
|------|------|------|
| PR 评审 | `terraform plan -out=tfplan` | 生成计划，上传制品审查 |
| 合并后执行 | `terraform apply tfplan` | 无需确认，直接执行审批过的计划 |

::: warning
保存计划模式下，不能再附加任何规划选项（`-var`、`-target` 等）或规划模式（`-destroy`、`-refresh-only`）——这些决策已在生成计划时固化在计划文件中。
:::

## apply 选项

以下选项是 `terraform apply` 特有的，或其行为与 `terraform plan` 存在差异。

### -auto-approve

跳过交互式确认提示，直接执行计划：

```bash
terraform apply -auto-approve
```

适用于自动化流水线。当传入保存的计划文件时，此参数会被忽略——因为传入计划文件本身就代表审批。

::: warning
`-auto-approve` 应配合精细的访问控制和审计日志使用，避免在无人知晓的情况下变更生产环境。
:::

### -input=false

禁用所有交互提示（包括确认提示和变量输入提示）。存在未赋值的变量时，Terraform 会直接报错而非提示输入。非交互式环境通常将其与 `-auto-approve` 或计划文件一起使用：

```bash
terraform apply -input=false -auto-approve
```

### -json

启用机器可读的 [JSON Lines](https://jsonlines.org/) 输出，适用于 CI/CD 日志采集和脚本解析。此选项隐含 `-input=false`，因此必须同时传入 `-auto-approve` 或计划文件：

```bash
terraform apply -auto-approve -json
terraform apply -json tfplan
```

输出为每行一个 JSON 对象，包含操作类型（`resource_changes`、`apply_complete` 等）和时序信息。

### -compact-warnings

若只有警告没有错误，以精简格式显示警告（仅摘要，不展开详情）：

```bash
terraform apply -compact-warnings -auto-approve
```

### -parallelism

限制并发操作数量，默认为 `10`。降低并发有助于避免触发云服务商的 API 速率限制：

```bash
terraform apply -auto-approve -parallelism=5
```

## 规划模式与规划选项

在自动规划模式（不使用计划文件）下，`terraform apply` 支持与 `terraform plan` 完全相同的规划模式和规划选项：

- **规划模式**：`-destroy`、`-refresh-only`
- **规划选项**：`-var`、`-var-file`、`-target`、`-replace`、`-refresh=false`

详见 [terraform plan —— 规划模式](/terraform-cli-plan#规划模式) 和 [规划选项](/terraform-cli-plan#规划选项)。

常见组合：

```bash
# 销毁全部资源
terraform apply -destroy -auto-approve

# 只应用到指定资源（应急手段，非常规方式）
terraform apply -target=aws_s3_bucket.app -auto-approve

# 强制重建损坏的资源（replace 旧版 terraform taint）
terraform apply -replace=aws_s3_bucket.app -auto-approve

# 只更新 state，不修改实际资源
terraform apply -refresh-only -auto-approve
```

## 通用参数

`-json`、`-no-color`、`-input`、`-lock`、`-lock-timeout` 等通用参数同样适用于 `terraform apply`。详见 [CLI 基础命令 — 跨命令通用参数](/terraform-cli-basic#跨命令通用参数)。

<KillercodaEmbed src="https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-cli-apply" />
