---
order: 92
title: plan
group: Terraform CLI
group_order: 9
---

# terraform plan

`terraform plan` 创建执行计划，让你在真正变更基础设施之前预览 Terraform 将做什么。

默认情况下，`terraform plan` 会：

1. 读取所有已存在远端资源的当前状态，确保本地 state 是最新的
2. 对比当前配置与 state 中的差异
3. 输出一份变更方案——告诉你哪些资源将被创建、修改或销毁

`terraform plan` 本身**不会**实际执行任何变更。若不加 `-out` 保存计划，它产生的是一份"推测性计划"（speculative plan），供人工审查或代码评审使用。

## 用法

```bash
terraform plan [options]
```

## 理解计划输出

每个资源行前的符号代表操作类型：

| 符号 | 含义 |
|------|------|
| `+` | 将被创建 |
| `-` | 将被销毁 |
| `~` | 将被原地修改（update） |
| `-/+` | 将先销毁再重建（replace，默认行为） |
| `+/-` | 将先新建再销毁（replace，配置了 `create_before_destroy = true`） |
| `<=` | 将被读取（data source） |

计划末尾汇总行如 `Plan: 2 to add, 1 to change, 0 to destroy` 是快速了解变更规模的入口。

## 规划模式

规划模式互斥，同时只能激活一种。

### -destroy

创建一份目标为**销毁所有受管资源**的计划，等同于 `terraform destroy` 的预览：

```bash
terraform plan -destroy
```

适用于暂态开发环境的清理确认。

### -refresh-only

创建一份目标为**只更新 state 文件**的计划，将 state 与远端实际状态对齐，而不修改任何资源配置。

```bash
terraform plan -refresh-only
```

典型场景：有人在 Terraform 之外手动修改了资源，需要把这些变更"收回"到 state，但又不想撤销那些修改。

::: warning
`-refresh-only` 与 `-destroy` 不能同时使用。
:::

## 规划选项

以下选项同样适用于 `terraform apply`。

### -var 与 -var-file

在命令行临时覆盖输入变量值：

```bash
terraform plan -var 'environment=prod'
terraform plan -var 'environment=prod' -var 'app_name=api'
```

`::: warning
等号两侧不能有空格，否则 Terraform 会报错。
:::

从 `.tfvars` 文件批量传入变量，更适合有多个变量的场景：

```bash
terraform plan -var-file=prod.tfvars
```

两个选项可以叠加使用，后面的值会覆盖前面的。

### -target

将计划聚焦于指定资源及其依赖，忽略其他所有资源：

```bash
terraform plan -target=aws_s3_bucket.app
terraform plan -target=module.vpc
```

Terraform 会自动包含目标资源的上游依赖。

::: warning
`-target` 仅用于故障恢复或规避 Terraform 限制等**特殊场景**，不应作为日常工作流的一部分。在大型配置中如需按模块独立管理，应将配置拆分为多个独立目录，通过 data source 共享数据。
:::

### -replace

指示 Terraform 将某个资源**先销毁再重建**（即使该资源本应无变更或只是更新）：

```bash
terraform plan -replace=aws_s3_bucket.app
```

适用于远端资源已损坏、需要通过重建恢复的场景。替代了旧版本中的 `terraform taint`。

可多次使用以同时替换多个资源：

```bash
terraform plan -replace=aws_s3_bucket.app -replace=aws_s3_bucket.logs
```

::: warning
`-replace` 不能与 `-destroy` 同时使用。
:::

### -refresh=false

跳过在规划前同步远端资源状态的步骤，完全依赖本地 state 进行计划，速度更快：

```bash
terraform plan -refresh=false
```

缺点是可能忽略别人在 Terraform 之外对资源做的变更。不能在 `-refresh-only` 模式下使用。

## 其他选项

### -out

将生成的计划保存到文件，稍后通过 `terraform apply tfplan` 精确执行该计划：

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

这是 CI/CD 中推荐的两步工作流：先 plan 产出计划文件，审批通过后 apply 该文件，确保执行的正是经过审批的内容。

::: warning
计划文件以不透明二进制格式存储，包含完整的配置、变量值（含敏感值）和所有计划选项。**请将计划文件视为潜在敏感制品**，不要提交到代码仓库，不要公开存储。
:::

使用 `terraform show` 可以以人类可读格式查看已保存的计划：

```bash
terraform show tfplan
```

### -detailed-exitcode

改变命令退出码的语义，使得脚本可以区分"无变更"和"有变更"两种成功情况：

| 退出码 | 含义 |
|--------|------|
| `0` | 成功，且计划为空（无变更） |
| `1` | 执行出错 |
| `2` | 成功，且计划非空（存在变更） |

```bash
terraform plan -detailed-exitcode
echo "Plan exit code: $?"
```

在 CI 中配合 `-out` 使用，退出码 `2` 可作为"需要 apply"的信号。

### -compact-warnings

如果只有警告没有错误，则以精简格式显示警告（仅显示摘要，不显示详情）：

```bash
terraform plan -compact-warnings
```

### -parallelism

限制 Terraform 并发操作的最大数量，默认为 `10`：

```bash
terraform plan -parallelism=5
```

### 通用参数

`-json`、`-no-color`、`-input`、`-lock`、`-lock-timeout` 等通用参数同样适用于 `terraform plan`。详见 [CLI 基础命令 — 跨命令通用参数](/terraform-cli-basic#跨命令通用参数)。

<KillercodaEmbed src="https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-cli-plan" />
