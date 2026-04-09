---
order: 94
title: destroy
group: Terraform CLI
group_order: 9
---

# terraform destroy

`terraform destroy` 销毁当前配置管理的所有远端资源。它是 `terraform apply -destroy` 的便捷别名。

虽然你通常不会在生产环境中销毁长期存在的资源，但 Terraform 常被用来管理开发/测试等临时环境——`terraform destroy` 可以在工作结束后一键清理所有临时资源。

## 用法

```bash
terraform destroy [options]
```

等价于：

```bash
terraform apply -destroy
```

因此，`terraform destroy` 接受 `terraform apply` 的大部分选项（但不接受计划文件参数，且强制使用 destroy 规划模式）。

## 执行流程

运行 `terraform destroy` 后，Terraform 会：

1. 刷新 state，确保了解远端资源的最新状态
2. 输出一份销毁计划——所有资源行首均显示 `-` 符号
3. 显示确认提示，等待输入 `yes`
4. 按照依赖关系逆序销毁资源

```
Plan: 0 to add, 0 to change, 3 to destroy.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value:
```

::: warning
`terraform destroy` 不可撤销。一旦输入 `yes`，所有受管资源将被永久删除。务必在执行前仔细确认销毁范围。
:::

## 预览销毁（不实际执行）

用 `terraform plan -destroy` 可以生成一份"推测性销毁计划"，预览哪些资源将被销毁，而不实际执行任何操作：

```bash
terraform plan -destroy
```

这与你在 `terraform destroy` 中看到的计划内容完全一致，但不会出现确认提示，也不会执行销毁。适合在 PR 评审阶段展示销毁影响。

## 常用选项

### -auto-approve

跳过交互式确认，直接执行销毁：

```bash
terraform destroy -auto-approve
```

::: warning
`-auto-approve` 跳过了最后一道安全防线。在自动化环境中使用时，应确保有完善的访问控制和审计日志。
:::

### -target

只销毁指定资源及其依赖，保留其他资源：

```bash
terraform destroy -target=aws_s3_bucket.logs
```

可多次使用以同时指定多个销毁目标：

```bash
terraform destroy -target=aws_s3_bucket.app -target=aws_s3_bucket.logs
```

::: warning
`-target` 销毁后，配置与 state 之间仍有差距。如需让配置与 state 重新对齐，应删除已销毁资源的 resource 块，或执行 `terraform apply` 重新创建它们。
:::

### -var 与 -var-file

当配置中使用变量构建资源标识时，需要传入正确的变量值才能定位到对应的远端资源：

```bash
terraform destroy -var-file=prod.tfvars
```

### 通用参数

`-json`、`-no-color`、`-input`、`-lock`、`-lock-timeout`、`-parallelism` 等通用参数同样适用。详见 [CLI 基础命令 — 跨命令通用参数](/terraform-cli-basic#跨命令通用参数)。

## destroy 与 apply -destroy 的区别

两者功能完全等价，区别仅在于使用场景：

| | `terraform destroy` | `terraform apply -destroy` |
|---|---|---|
| 本质 | `apply -destroy` 的便捷别名 | 原始形式 |
| 计划文件 | 不支持 | 不支持（`-destroy` 模式下也不支持） |
| 与其他选项组合 | 支持 `-target`、`-var` 等 | 支持 `-target`、`-var` 等 |
| 推荐场景 | 日常终端使用（语义更清晰） | CI/CD 脚本（与 `apply` 保持一致的命令格式） |

<KillercodaEmbed src="https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-cli-destroy" />
