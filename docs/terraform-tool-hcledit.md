---
order: 17
title: hcledit
group: 周边工具
group_order: 17
---

# hcledit：HCL 命令行编辑器

[hcledit](https://github.com/minamijoyo/hcledit) 是一个命令行工具，用于程序化地读取和修改 HCL 文件。当你需要在自动化脚本或 CI/CD 流水线中批量修改 Terraform 配置时，`sed`/`awk` 容易破坏 HCL 语法结构，而 `hcledit` 基于 HCL 语法树操作，**保留注释和格式**，是更安全的选择。

## 核心特性

- **CLI 友好**：从 stdin 读入、stdout 输出，方便管道组合
- **基于语法树**：修改操作保留原有注释和空白格式
- **无需 Schema**：不依赖任何特定应用（Terraform、Packer 等）的 Schema
- **支持 HCL2**：Terraform 0.12+ 使用的语法格式

## 安装

```bash
# macOS (Homebrew)
brew install minamijoyo/hcledit/hcledit

# Go install（需要 Go 1.23+）
go install github.com/minamijoyo/hcledit@latest

# Linux（下载预编译二进制）
VERSION=0.2.17
curl -sSL "https://github.com/minamijoyo/hcledit/releases/download/v${VERSION}/hcledit_${VERSION}_linux_amd64.tar.gz" \
  | tar xz -C /usr/local/bin hcledit

# 验证安装
hcledit version
```

## 地址语法

`hcledit` 使用**点分地址**定位 HCL 中的块和属性。地址格式为：

```
块类型.标签1.标签2...属性名
```

对于 Terraform 配置，常见地址示例：

| HCL 结构 | 地址 |
|----------|------|
| `resource "aws_s3_bucket" "app"` 的 `bucket` 属性 | `resource.aws_s3_bucket.app.bucket` |
| `variable "name"` 的 `default` 属性 | `variable.name.default` |
| `provider "aws"` 块 | `provider.aws` |
| `terraform` 块下 `required_version` | `terraform.required_version` |
| `locals` 块下 `project` | `locals.project` |

如果标签中包含 `.`，需要用反斜杠转义：`resource.foo\.bar.attr`。

## attribute 子命令

### attribute get — 读取属性值

```bash
cat main.tf | hcledit attribute get resource.aws_s3_bucket.app.bucket
```

输出属性的原始值（含引号），例如 `"my-bucket"`。

### attribute set — 设置属性值

```bash
cat main.tf | hcledit attribute set resource.aws_s3_bucket.app.bucket '"new-bucket"'
```

注意值需要是合法的 HCL 表达式。字符串值需要用**双层引号**：外层单引号保护 shell，内层双引号是 HCL 字符串语法。

### attribute append — 追加属性

```bash
cat main.tf | hcledit attribute append resource.aws_s3_bucket.app.force_destroy 'true' --newline
```

`--newline` 在追加的属性前插入一个空行，改善可读性。

### attribute rm — 删除属性

```bash
cat main.tf | hcledit attribute rm resource.aws_s3_bucket.app.tags
```

### attribute mv — 重命名属性

```bash
cat main.tf | hcledit attribute mv resource.aws_s3_bucket.app.tags resource.aws_s3_bucket.app.tags_all
```

### attribute replace — 同时修改属性名和值

```bash
cat main.tf | hcledit attribute replace resource.aws_s3_bucket.app.bucket new_bucket '"replaced-bucket"'
```

## block 子命令

### block list — 列出所有块

```bash
cat main.tf | hcledit block list
```

输出所有顶层块的地址，例如：

```
terraform
provider.aws
resource.aws_s3_bucket.app
resource.aws_s3_bucket.logs
```

### block get — 获取整个块

```bash
cat main.tf | hcledit block get resource.aws_s3_bucket.app
```

输出完整的块内容（含花括号和所有内部属性）。

### block new — 创建新块

```bash
cat main.tf | hcledit block new resource.aws_s3_bucket.archive --newline
```

在文件末尾追加一个空块。

### block append — 在块内追加嵌套块

```bash
cat main.tf | hcledit block append resource.aws_s3_bucket.app lifecycle --newline
```

### block rm — 删除块

```bash
cat main.tf | hcledit block rm resource.aws_s3_bucket.logs
```

### block mv — 重命名块

```bash
cat main.tf | hcledit block mv resource.aws_s3_bucket.app resource.aws_s3_bucket.main
```

## body 子命令

### body get — 获取块体

```bash
cat main.tf | hcledit body get resource.aws_s3_bucket.app
```

与 `block get` 不同，`body get` 只返回块**内部的内容**，不包含块头和花括号。

## 文件操作模式

`hcledit` 支持两种输入方式：

**管道模式**（默认）— 从 stdin 读入，输出到 stdout：

```bash
cat main.tf | hcledit attribute get resource.aws_s3_bucket.app.bucket
```

**文件模式** — 通过 `-f` 指定输入文件，配合 `-u` 原地修改：

```bash
# 只读取，不修改文件
hcledit attribute get resource.aws_s3_bucket.app.bucket -f main.tf

# 原地修改文件
hcledit attribute set resource.aws_s3_bucket.app.bucket '"new-bucket"' -f main.tf -u
```

::: warning
使用 `-u` 会直接修改文件，操作前建议先用不带 `-u` 的命令预览变更，或确保文件已被版本控制。
:::

## 实用场景

### 批量更新 Provider 版本

```bash
find . -name "*.tf" -exec grep -l 'required_providers' {} \; | while read f; do
  hcledit attribute set \
    terraform.required_providers.aws.version '"~> 5.0"' \
    -f "$f" -u
done
```

### 在 CI 中提取配置信息

```bash
# 读取当前 required_version 约束
hcledit attribute get terraform.required_version -f main.tf
```

### 为所有资源添加通用标签

```bash
for resource in $(hcledit block list -f main.tf | grep '^resource\.'); do
  hcledit attribute set "${resource}.tags" 'local.common_tags' -f main.tf -u
done
```

---

## 动手实验

<KillercodaEmbed src="https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-tool-hcledit" />
