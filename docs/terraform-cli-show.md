---
order: 96
title: show
group: Terraform CLI
group_order: 9
---

# terraform show

`terraform show` 以人类可读的格式展示 Terraform 状态或计划文件的内容。它是检视基础设施当前状态和审查执行计划的核心命令。

## 用法

```bash
terraform show [options] [file]
```

- 不传 `file` 时，显示当前工作目录中的最新状态快照（`terraform.tfstate`）。
- 传入由 `terraform plan -out` 生成的计划文件时，以人类可读格式显示该计划的内容。

## 查看当前状态

```bash
terraform show
```

如果状态为空（从未执行过 `apply`），输出为空白。如果已有受管资源，输出包含每个资源的完整属性：

```
# aws_s3_bucket.app:
resource "aws_s3_bucket" "app" {
    arn            = "arn:aws:s3:::myapp-dev-app"
    bucket         = "myapp-dev-app"
    hosted_zone_id = "Z3AQBSTGFYJSTF"
    id             = "myapp-dev-app"
    tags           = {
        "Environment" = "dev"
        "ManagedBy"   = "Terraform"
    }
    # ...
}
```

也可以结合 `grep` 快速定位关键信息：

```bash
terraform show | grep bucket
```

## 查看计划文件

先生成一份保存的计划文件，再用 `show` 查看其内容：

```bash
terraform plan -out=tfplan
terraform show tfplan
```

`show` 将计划文件渲染为与 `terraform plan` 终端输出相同的人类可读格式，包含资源变更摘要（`+`、`~`、`-`）和属性差异。这在以下场景中尤其有用：

- CI/CD 中提前生成计划，稍后用 `show` 重新审查
- 将计划以文本形式记录到审计日志
- 在不同终端中审查同一份计划

::: tip
计划文件是二进制格式，`cat tfplan` 只会输出乱码。必须用 `terraform show` 才能正确解读。
:::

## 选项

### -json

输出 JSON 格式，适用于脚本解析和自动化处理：

```bash
# 查看当前状态的 JSON 表示
terraform show -json

# 查看计划文件的 JSON 表示
terraform show -json tfplan
```

**状态 JSON** 包含 `format_version`、`terraform_version`、`values`（资源属性）等字段。

**计划 JSON** 包含 `resource_changes`（每个资源的变更动作和前后属性差异）、`planned_values`（变更后的预期状态）、`configuration`（模块配置）等字段。

::: warning
`-json` 输出中敏感值以明文显示。处理包含敏感数据的状态或计划时，注意保护输出内容。
:::

### -no-color

禁用带颜色的输出，适用于日志采集或不支持 ANSI 转义序列的终端：

```bash
terraform show -no-color
```

## 典型用法

```bash
# 查看当前状态中某个资源的属性
terraform show | grep -A 10 "aws_s3_bucket.app"

# 两步工作流中审查计划
terraform plan -out=tfplan
terraform show tfplan          # 人类可读
terraform show -json tfplan    # 机器可读

# 导出状态到文件用于离线分析
terraform show -json > state.json

# 结合 python3 格式化 JSON 输出
terraform show -json | python3 -m json.tool
```

## show 与相关命令的对比

| 命令 | 用途 | 输入 |
|------|------|------|
| `terraform show` | 展示状态或计划的完整内容 | 状态文件 / 计划文件 |
| `terraform state list` | 列出状态中的资源地址 | 只读状态 |
| `terraform state show <addr>` | 展示单个资源的属性 | 只读状态 + 资源地址 |
| `terraform output` | 只显示 output 值 | 只读状态 |
| `terraform plan` | 生成并展示执行计划 | 配置 + 状态 + 远端 |

`terraform show` 不会修改任何状态或资源，是一个纯只读的检视命令。

<KillercodaEmbed src="https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-cli-show" />
