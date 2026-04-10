---
order: 97
title: output
group: Terraform CLI
group_order: 9
---

# terraform output

`terraform output` 从状态文件中提取并显示 output 变量的值。它是在命令行查询基础设施信息、在脚本中提取数据、在模块间传递值的核心命令。

## 用法

```bash
terraform output [options] [NAME]
```

- 不传 `NAME` 时，显示根模块中声明的所有 output。
- 传入 `NAME` 时，只显示该 output 的值。

## 查看所有 output

```bash
terraform output
```

输出示例：

```
app_bucket      = "myapp-dev-app"
logs_bucket     = "myapp-dev-logs"
sessions_table  = "myapp-dev-sessions"
```

标记为 `sensitive` 的 output 在此处显示为 `<sensitive>`。

## 查看单个 output

```bash
terraform output app_bucket
```

输出该 output 的值（带引号）：

```
"myapp-dev-app"
```

::: tip
指定 output 名称时，即使该 output 标记为 `sensitive`，也会显示实际值。Terraform 只在列出所有 output 时才隐藏敏感值。
:::

## 选项

### -json

以 JSON 格式输出，适用于脚本解析和自动化处理：

```bash
# 所有 output 的 JSON
terraform output -json

# 单个 output 的 JSON
terraform output -json app_bucket
```

列出所有 output 时，每个 output 包含 `value`、`type`、`sensitive` 字段：

```json
{
  "app_bucket": {
    "value": "myapp-dev-app",
    "type": "string",
    "sensitive": false
  }
}
```

可以配合 `jq` 或 `python3` 提取特定值：

```bash
terraform output -json | python3 -c "import sys,json; print(json.load(sys.stdin)['app_bucket']['value'])"
```

### -raw

直接输出字符串值，不带引号和格式化，适合在 shell 脚本中直接使用：

```bash
terraform output -raw app_bucket
```

输出：

```
myapp-dev-app
```

`-raw` 只支持 string、number、bool 类型。对于 list、map 等复合类型，需使用 `-json`。

### -no-color

禁用带颜色的输出：

```bash
terraform output -no-color
```

## 自动化中的用法

### Shell 脚本集成

`-raw` 适合直接赋值给 shell 变量：

```bash
BUCKET=$(terraform output -raw app_bucket)
aws s3 ls "s3://$BUCKET"
```

### JSON 管道处理

`-json` 适合复杂数据结构的提取和处理：

```bash
# 提取列表中的第一个元素
terraform output -json instance_ips | jq -r '.[0]'

# 将所有 output 写入文件用于后续步骤
terraform output -json > outputs.json
```

### CI/CD 中传递值

在多阶段 CI/CD 流水线中，`terraform output` 常用于将基础设施信息传递给后续部署步骤：

```bash
# 基础设施阶段
terraform apply -auto-approve
terraform output -json > infra-outputs.json

# 应用部署阶段
BUCKET=$(cat infra-outputs.json | jq -r '.app_bucket.value')
```

## 注意事项

- `terraform output` 只显示**根模块**的 output。子模块的 output 必须在根模块中通过 `output` 块显式暴露。
- `-json` 和 `-raw` 输出中，`sensitive` 值以明文显示。
- 如果状态为空（从未执行过 `apply`），命令会报错：`No outputs found`。
- `terraform output` 是只读命令，不会修改状态或资源。

<KillercodaEmbed src="https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-cli-output" />
