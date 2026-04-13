---
order: 20
title: tflint
group: 周边工具
group_order: 17
---

# tflint：Terraform 代码静态分析工具

[tflint](https://github.com/terraform-linters/tflint) 是一个可扩展的、插件化的 Terraform 代码静态分析工具（Linter），用于在基础设施即代码（IaC）实践中提升 Terraform 配置的质量、安全性和一致性。

`terraform validate` 和 `terraform plan` 主要聚焦于语法和基础语义层面，而 `tflint` 更进一步——它能发现配置中的**错误**、**潜在风险**与**不规范用法**，类似于 Go 语言中的 [golangci-lint](https://golangci-lint.run/)。

## 解决什么问题

Terraform 本身的检查工具存在局限性：

- `terraform validate` 只校验语法正确性，不检查资源属性的合法性（如实例类型是否存在）
- `terraform plan` 需要连接云平台 API，无法在离线环境快速检查
- 两者都无法强制执行团队的编码规范和最佳实践

`tflint` 填补了这些空白：

| 能力 | 说明 |
|------|------|
| 废弃语法检测 | 识别已被标记为废弃的属性和用法 |
| 未使用声明检测 | 发现未使用的 variable、data source 等 |
| 云平台资源校验 | 通过插件检查实例类型、区域、属性合法性等 |
| 命名约定强制 | 强制资源/变量命名规范，支撑团队协作 |
| 自定义规则扩展 | 通过插件或配置实现企业内部合规要求 |

## 插件机制

tflint 的核心设计是**插件化**。内置的 `terraform` 插件提供 Terraform 语言规则，云平台插件提供特定云资源的检查规则：

| 插件 | 用途 |
|------|------|
| `terraform` | 内置插件，检查 Terraform 语言规范（废弃语法、未使用声明、命名等） |
| `aws` | AWS 资源属性校验（实例类型、安全组规则等） |
| `azurerm` | Azure 资源属性校验 |
| `google` | GCP 资源属性校验 |

## 安装

```bash
# Linux
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# macOS
brew install tflint

# Docker
docker run --rm -v $(pwd):/data -t ghcr.io/terraform-linters/tflint
```

## 使用方法

### 配置文件

项目根目录下创建 `.tflint.hcl`，定义所需插件及规则：

```hcl
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}
```

对于云平台项目，添加对应插件：

```hcl
plugin "aws" {
  enabled = true
  version = "0.19.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}
```

### 初始化与检查

```bash
# 下载插件（类似 terraform init）
tflint --init

# 执行检查
tflint
```

### 常用参数

| 参数 | 说明 |
|------|------|
| `--init` | 下载配置文件中声明的插件 |
| `--recursive` | 递归扫描子目录 |
| `-f compact` | 紧凑输出格式 |
| `-f json` | JSON 输出格式（适合 CI） |
| `--minimum-failure-severity=warning` | 设置最低告警级别 |
| `--config=path` | 指定配置文件路径 |
| `--fix` | 自动修复部分问题 |

## terraform 插件内置规则

使用 `preset = "recommended"` 时，以下规则默认启用：

| 规则 | 说明 |
|------|------|
| `terraform_deprecated_interpolation` | 检测废弃的插值语法 `"${var.x}"` → `var.x` |
| `terraform_deprecated_index` | 检测废弃的索引语法 `.0` → `[0]` |
| `terraform_required_providers` | required_providers 块必须声明 source 和 version |
| `terraform_required_version` | 必须声明 required_version |
| `terraform_typed_variables` | variable 块必须声明 type |
| `terraform_unused_declarations` | 检测未使用的 variable、data、locals |
| `terraform_unused_required_providers` | 检测声明但未使用的 provider |

以下规则不在 `recommended` 预设中，需手动启用：

| 规则 | 说明 |
|------|------|
| `terraform_naming_convention` | 资源/变量命名必须使用 snake_case |
| `terraform_documented_outputs` | output 块必须有 description |
| `terraform_documented_variables` | variable 块必须有 description |

可以在配置文件中单独启用或禁用某条规则：

```hcl
rule "terraform_naming_convention" {
  enabled = true
}
```

## 与 terraform validate 的对比

| 对比 | `terraform validate` | `tflint` |
|------|---------------------|----------|
| 语法检查 | ✅ | ✅ |
| 类型检查 | ✅ | ✅ |
| 废弃语法检测 | ❌ | ✅ |
| 未使用声明检测 | ❌ | ✅ |
| 命名约定检查 | ❌ | ✅ |
| 云平台资源校验 | ❌ | ✅（通过插件） |
| 需要 provider 连接 | ✅（init 后） | ❌ |
| 自定义规则 | ❌ | ✅ |

推荐的使用顺序：先 `tflint`（静态检查），再 `terraform validate`（语义检查），最后 `terraform plan`（云端验证）。

## 在 CI/CD 中使用

tflint 非常适合集成到 CI 管道中：

```yaml
# GitHub Actions 示例
- uses: terraform-linters/setup-tflint@v4
  with:
    tflint_version: v0.52.0

- name: Init TFLint
  run: tflint --init
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

- name: Run TFLint
  run: tflint -f compact
```

## 与其他工具的关系

| 工具 | 职责 |
|------|------|
| `terraform fmt` | 缩进、对齐、空白格式化 |
| `terraform validate` | 语法和基础语义检查 |
| `tflint` | 静态分析、废弃语法、命名规范、云资源校验 |
| `avmfix` | 属性排序、块排列、文件归位 |
| `checkov` / `trivy` | 安全合规扫描 |

---

## 动手实验

<KillercodaEmbed src="https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-tool-tflint" />
