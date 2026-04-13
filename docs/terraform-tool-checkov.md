---
order: 21
title: checkov
group: 周边工具
group_order: 17
---

# Checkov：Terraform 安全合规扫描工具

[Checkov](https://github.com/bridgecrewio/checkov) 是由 Bridgecrew（现属 Palo Alto Networks Prisma Cloud）开发的开源静态分析工具，专注于基础设施即代码（IaC）的安全检查。它通过在云资源部署之前扫描配置代码，及时发现不安全的配置和合规隐患。

`tflint` 侧重于代码规范和语法质量，而 `checkov` 更关注的是**安全最佳实践**、**合规性**以及**策略违规**——它是云环境的"安全守门人"。

## 解决什么问题

当团队使用 Terraform 管理云基础设施时，配置错误是导致安全事故的主要原因之一：

- S3 存储桶未开启加密或版本控制
- 安全组规则过于宽松，端口暴露在公网
- 数据库对公网开放访问
- 代码中硬编码了 AWS 密钥等凭证
- 资源未启用日志审计，不符合合规要求

这些问题如果在部署后才发现，修复成本极高。Checkov 通过"左移安全"（Shift Left）的方式，在代码阶段就捕获这些风险。

## 主要功能

| 功能 | 说明 |
|------|------|
| 安全最佳实践检查 | 内置上千条针对 AWS、Azure、GCP 等云环境的安全基线规则 |
| 合规性扫描 | 支持 CIS 基线、PCI-DSS、GDPR 等常见合规标准 |
| 策略违规检测 | 支持自定义策略（Python 或 YAML），检查组织内部规范 |
| 敏感信息扫描 | 检测代码中硬编码的凭证、密钥等敏感数据 |
| 多框架支持 | 除 Terraform 外，还支持 CloudFormation、Kubernetes、Helm 等 |
| 丰富的输出格式 | CLI、JSON、JUnit XML、SARIF 等多种格式 |

## 安装

```bash
# 使用 pip 安装（推荐）
pip install checkov

# 使用 Docker
docker run --rm -v "$(pwd):/iac" bridgecrew/checkov -d /iac --framework terraform

# macOS
brew install checkov
```

## 使用方法

### 基本扫描

```bash
# 扫描目录
checkov -d /path/to/terraform/code

# 扫描单个文件
checkov -f main.tf

# 只运行特定规则
checkov -d . --check CKV_AWS_20,CKV_AWS_57

# 跳过特定规则
checkov -d . --skip-check CKV_AWS_20
```

### 输出格式

```bash
# JSON 格式
checkov -d . -o json

# JUnit XML（适合 CI）
checkov -d . -o junitxml

# 紧凑格式
checkov -d . --compact
```

### 常用参数

| 参数 | 说明 |
|------|------|
| `-d` / `--directory` | 扫描指定目录 |
| `-f` / `--file` | 扫描指定文件 |
| `--check` | 只运行指定规则 |
| `--skip-check` | 跳过指定规则 |
| `-o` / `--output` | 输出格式（cli/json/junitxml/sarif） |
| `--soft-fail` | 即使有违规也返回退出码 0 |
| `--framework` | 指定扫描框架（terraform/cloudformation 等） |
| `--compact` | 紧凑输出，不显示违规代码块 |
| `--list` | 列出所有可用的检查规则 |

## 扫描结果解读

Checkov 的输出包含：

- **Passed checks**：通过检查的资源
- **Failed checks**：未通过检查的资源，附带规则 ID、描述、违规代码位置和修复建议
- **Skipped checks**：被跳过的检查

每条失败记录包含规则编号（如 `CKV_AWS_19`）、严重等级和受影响资源的详细信息。

## 与其他工具的对比

| 对比 | `terraform validate` | `tflint` | `checkov` |
|------|---------------------|----------|-----------|
| 语法检查 | ✅ | ✅ | ❌ |
| 代码规范 | ❌ | ✅ | ❌ |
| 安全扫描 | ❌ | ❌ | ✅ |
| 合规检查 | ❌ | ❌ | ✅ |
| 敏感信息检测 | ❌ | ❌ | ✅ |
| 自定义策略 | ❌ | ✅（插件） | ✅（Python/YAML） |

推荐的使用顺序：先 `tflint`（代码规范），再 `checkov`（安全合规），最后 `terraform plan`（云端验证）。

## 在 CI/CD 中使用

```yaml
# GitHub Actions 示例
- uses: actions/checkout@v4
- uses: bridgecrewio/checkov-action@master
  with:
    directory: .
    framework: terraform
    soft_fail: false
```

## 跳过特定检查（内联注释）

在 Terraform 代码中可以用注释跳过特定规则：

```hcl
resource "aws_s3_bucket" "example" {
  #checkov:skip=CKV_AWS_18:Access logging not required for this bucket
  bucket = "my-bucket"
}
```

## 与其他工具的关系

| 工具 | 职责 |
|------|------|
| `terraform fmt` | 缩进、对齐、空白格式化 |
| `tflint` | 静态分析、废弃语法、命名规范 |
| `checkov` | 安全最佳实践、合规扫描、敏感信息检测 |
| `avmfix` | 属性排序、块排列、文件归位 |

---

## 动手实验

<KillercodaEmbed src="https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-tool-checkov" />
