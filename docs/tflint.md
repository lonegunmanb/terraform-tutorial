---
order: 4
title: TFLint 代码检查
---

# TFLint 代码检查

[TFLint](https://github.com/terraform-linters/tflint) 是一个可插拔的 Terraform Linter，能够在 `terraform plan` 之前捕获潜在的错误和不规范的写法。

## 📝 核心概念

### 为什么需要 Lint？

`terraform validate` 只检查语法是否合法，但不会检查：

- 是否使用了无效的实例类型（如 `t2.micro_typo`）
- 是否遗漏了推荐的标签
- 是否使用了已废弃的资源属性
- 是否违反了团队的命名约定

TFLint 填补了这个空白。

### 基本用法

```bash
# 初始化（下载规则插件）
tflint --init

# 检查当前目录
tflint

# 指定配置文件
tflint --config .tflint.hcl
```

### 配置文件示例

```hcl
# .tflint.hcl
plugin "aws" {
  enabled = true
  version = "0.31.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

rule "terraform_naming_convention" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}
```

### 常见规则

| 规则 | 说明 |
|------|------|
| `terraform_naming_convention` | 检查命名是否符合约定（snake_case） |
| `terraform_documented_variables` | 检查变量是否有 description |
| `terraform_unused_declarations` | 检查是否有未使用的变量或 data source |
| `aws_instance_invalid_type` | 检查 EC2 实例类型是否有效 |

## 🧪 动手实验

在下面的终端中完成以下操作：

1. 运行 `tflint --init` 初始化 TFLint
2. 运行 `tflint` 查看检查结果
3. 根据提示修复代码中的问题
4. 再次运行 `tflint` 确认所有检查通过

<KillercodaEmbed src="https://killercoda.com/lonegunman/scenario/terraform-tflint~embed" />
