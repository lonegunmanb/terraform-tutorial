---
order: 100
title: state
group: Terraform CLI
group_order: 9
---

# terraform state

`terraform state` 提供一组子命令，用于直接读取和修改 Terraform 状态文件。常规工作流中，`plan` / `apply` 会自动维护状态，但在代码重构、资源迁移、调试等场景下，手动操作状态是不可避免的。

::: warning
`terraform state` 的写入子命令（`mv`、`rm`、`replace-provider`）会直接修改状态文件。操作前建议先备份状态，或使用 `-dry-run` 预览变更。
:::

## 子命令一览

| 子命令 | 用途 | 是否修改状态 |
|--------|------|:---:|
| `state list` | 列出状态中的所有资源 | 否 |
| `state show` | 显示单个资源的详细属性 | 否 |
| `state mv` | 在状态中移动/重命名资源 | **是** |
| `state rm` | 从状态中移除资源（不销毁远端对象） | **是** |
| `state pull` | 下载并输出原始状态 JSON | 否 |
| `state replace-provider` | 替换状态中的 provider 来源 | **是** |

---

## state list — 列出资源

```bash
terraform state list [options] [address...]
```

不带参数时列出状态中**所有**资源实例：

```bash
terraform state list
# aws_s3_bucket.app
# aws_dynamodb_table.locks
```

可通过部分地址过滤：

```bash
# 只看某种资源类型
terraform state list aws_s3_bucket

# 只看某模块下的资源
terraform state list module.network
```

### -id 选项

按资源的远端 ID 过滤：

```bash
terraform state list -id=my-bucket
```

当你知道远端 ID 但不确定 Terraform 里叫什么名字时非常有用。

---

## state show — 查看资源详情

```bash
terraform state show [options] ADDRESS
```

显示一个资源实例的全部属性，输出格式与 `terraform show` 对单个资源的展示类似，但只从状态文件中读取，不会查询远端：

```bash
terraform state show aws_s3_bucket.app
# resource "aws_s3_bucket" "app" {
#     arn           = "arn:aws:s3:::my-app-bucket"
#     bucket        = "my-app-bucket"
#     ...
# }
```

支持 `count` 和 `for_each` 寻址：

```bash
terraform state show 'aws_s3_bucket.env["dev"]'
terraform state show 'aws_instance.web[0]'
```

---

## state mv — 移动/重命名资源

```bash
terraform state mv [options] SOURCE DESTINATION
```

修改状态中资源的地址，**不触发销毁和重建**。这是代码重构时最常用的子命令。

### 典型场景

**重命名资源：**

```bash
# 配置中将 aws_s3_bucket.app 改名为 aws_s3_bucket.application
terraform state mv aws_s3_bucket.app aws_s3_bucket.application
```

**将资源移入模块：**

```bash
# 将根模块中的资源移入子模块
terraform state mv aws_s3_bucket.app module.storage.aws_s3_bucket.app
```

**将模块整体移入另一个模块：**

```bash
terraform state mv module.storage module.infra.module.storage
```

**count / for_each 地址：**

```bash
# count 索引
terraform state mv 'aws_instance.web[0]' 'aws_instance.web[1]'

# for_each 键名（注意 shell 引号转义）
terraform state mv 'aws_s3_bucket.env["dev"]' 'aws_s3_bucket.env["develop"]'
```

### -dry-run 预览

```bash
terraform state mv -dry-run aws_s3_bucket.app aws_s3_bucket.application
# Would move "aws_s3_bucket.app" to "aws_s3_bucket.application"
```

先预览再执行，避免误操作。

::: tip
Terraform 1.1+ 推荐使用声明式的 `moved` 块来替代 `terraform state mv`。`moved` 块写在配置中，可以进入版本控制、Code Review，并在 `plan` 阶段预览。详见[代码重构](/refactor_module)章节。
:::

---

## state rm — 移除资源

```bash
terraform state rm [options] ADDRESS...
```

从状态中移除资源记录，**但不销毁远端对象**。被移除的资源将不再被 Terraform 管理。

```bash
terraform state rm aws_s3_bucket.legacy
# Removed aws_s3_bucket.legacy
# Successfully removed 1 resource instance(s).
```

移除后运行 `terraform plan`，Terraform 会认为资源不存在并计划**重新创建**。如果你只是想让 Terraform "忘记"某个资源而不重建它，需要同时从配置文件中删除对应的 resource 块。

### 移除整个模块

```bash
terraform state rm module.legacy
```

### -dry-run 预览

```bash
terraform state rm -dry-run aws_s3_bucket.legacy
# Would remove aws_s3_bucket.legacy
```

### count / for_each 地址

```bash
terraform state rm 'aws_instance.web[0]'
terraform state rm 'aws_s3_bucket.env["dev"]'
```

::: tip
Terraform 1.7+ 推荐使用声明式的 `removed` 块来替代 `terraform state rm`。`removed` 块写在配置中，可以在 `plan` 阶段预览移除效果。详见 [HashiCorp 文档](https://developer.hashicorp.com/terraform/language/resources/syntax#removing-resources)。
:::

---

## state pull — 下载原始状态

```bash
terraform state pull
```

将当前状态以 JSON 格式输出到标准输出。适合用管道传给 `jq` 做提取，或保存为文件供离线分析：

```bash
# 查看状态版本和 Terraform 版本
terraform state pull | python3 -c "
import sys, json
state = json.load(sys.stdin)
print('Serial:', state.get('serial'))
print('Terraform:', state.get('terraform_version'))
"

# 导出为文件
terraform state pull > state-backup.json
```

在使用远端 Backend 时，`state pull` 会从远端下载最新状态。

---

## state replace-provider — 替换 provider 来源

```bash
terraform state replace-provider [options] FROM TO
```

当 provider 的源地址发生变化时（如组织更名、迁移到私有 Registry），使用此命令更新状态中所有相关资源的 provider 绑定：

```bash
terraform state replace-provider hashicorp/aws registry.acme.corp/acme/aws
```

### 选项

- `-auto-approve`：跳过交互式确认
- `-lock=false`：不获取状态锁（多人协作时慎用）

此命令会在修改前自动创建备份。

---

## 通用注意事项

1. **自动备份**：所有写入子命令在修改状态前会自动创建 `.tfstate.backup` 文件。
2. **状态锁**：默认会获取状态锁，可通过 `-lock=false` 跳过（不推荐）。
3. **管道友好**：输出格式设计为可被 Unix 工具链（`grep`、`awk`、`jq`）处理。
4. **远端 Backend**：所有子命令自动透传远端 Backend，无需额外配置。

## 交互式实验

<KillercodaEmbed src="https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-cli-state" />
