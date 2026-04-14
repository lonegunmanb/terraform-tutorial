---
order: 22
title: conftest
group: 周边工具
group_order: 17
---

# Conftest：基于 OPA 的 Terraform 策略即代码工具

[Conftest](https://github.com/open-policy-agent/conftest) 是一款基于 [Open Policy Agent (OPA)](https://www.openpolicyagent.org/) 的命令行工具，专门用于对结构化配置数据编写和执行策略测试。它使用 OPA 的 [Rego](https://www.openpolicyagent.org/docs/latest/policy-language/) 语言编写策略，可以在部署前自动检查 Terraform 配置是否符合组织的合规要求。

`checkov` 使用内置规则库进行安全扫描，而 `conftest` 更灵活——它让团队用 **Rego 语言自定义策略**，针对 Terraform Plan 的 JSON 输出进行精确检查，适合实现组织特有的合规要求。

## 解决什么问题

在大规模 Terraform 模块治理中，团队面临的挑战不仅是通用的安全最佳实践，还有组织特有的合规需求：

- 所有 S3 存储桶必须开启版本控制和服务端加密
- 所有资源必须包含组织要求的标签（如 Team、CostCenter）
- 禁止使用某些不安全的实例类型或配置
- 模块版本必须在允许范围内
- 生产环境必须满足特定的高可用性要求

这些需求因组织而异，通用工具的内置规则无法完全覆盖。Conftest 让团队将这些要求编写成可执行的策略代码，实现**策略即代码（Policy as Code）**。

## 工作流程

与 `checkov` 等直接扫描 `.tf` 文件的工具不同，Conftest 的典型工作流程是：

1. **生成 Terraform Plan JSON**：`terraform plan -out=tfplan.binary && terraform show -json tfplan.binary > tfplan.json`
2. **编写 Rego 策略**：在 `policy/` 目录下编写 `.rego` 文件定义检查规则
3. **运行 Conftest**：`conftest test tfplan.json`

这种基于 Plan JSON 的方式有一个重要优势——它能看到 Terraform **即将执行的变更**，包括计算后的值、资源间的引用关系等，比静态扫描 `.tf` 源文件更精确。

## 安装

```bash
# Linux
curl -fsSL https://github.com/open-policy-agent/conftest/releases/download/v0.56.0/conftest_0.56.0_Linux_x86_64.tar.gz \
  | tar xz -C /usr/local/bin conftest

# macOS
brew install conftest

# Docker
docker run --rm -v $(pwd):/project openpolicyagent/conftest test tfplan.json
```

## 使用方法

### 基本命令

```bash
# 测试配置文件（默认从 policy/ 目录加载策略）
conftest test tfplan.json

# 指定策略目录
conftest test -p /path/to/policies tfplan.json

# 测试所有命名空间
conftest test --all-namespaces tfplan.json

# 指定输出格式
conftest test -o table tfplan.json
conftest test -o json tfplan.json
```

### 常用参数

| 参数 | 说明 |
|------|------|
| `-p` / `--policy` | 指定策略文件或目录（默认 `policy/`） |
| `-o` / `--output` | 输出格式（stdout/json/table/tap/junit） |
| `--all-namespaces` | 测试所有 Rego 命名空间 |
| `--namespace` | 只测试指定命名空间 |
| `--update` | 从远程 URL 拉取策略（支持 git、http） |
| `--no-fail` | 即使有失败也返回退出码 0 |

## Rego 策略基础

Conftest 使用 Rego 语言定义策略。核心概念很简单：

- `deny` 规则：返回非空值时表示策略违规（测试失败）
- `warn` 规则：返回非空值时表示警告（测试通过但有提示）
- `input`：被测试的数据（Terraform Plan JSON）

如果想要深入学习 Rego 语言，可以参考 [Rego 进阶教程](https://lonegunmanb.github.io/rego-tutorial/)。

```rego
package main

import rego.v1

# 拒绝没有开启版本控制的 S3 桶
deny contains msg if {
  resource := input.resource_changes[_]
  resource.type == "aws_s3_bucket_versioning"
  resource.change.after.versioning_configuration[_].status != "Enabled"
  msg := sprintf("S3 桶 '%s' 必须开启版本控制", [resource.address])
}
```

## Conftest 与 Checkov 的对比

| 对比 | `checkov` | `conftest` |
|------|-----------|-----------|
| 策略语言 | 内置规则 + Python/YAML | Rego（OPA） |
| 扫描对象 | `.tf` 源文件 | Terraform Plan JSON |
| 内置规则 | 上千条 | 无（需自行编写或引用社区策略库） |
| 灵活性 | 中等（可跳过/自定义） | 极高（完全自定义策略逻辑） |
| 学习曲线 | 低（开箱即用） | 中等（需学习 Rego） |
| 适用场景 | 通用安全最佳实践 | 组织特有的合规要求 |

两者可以互补：`checkov` 覆盖通用安全基线，`conftest` 实现组织特定策略。

## 在 CI/CD 中使用

```yaml
# GitHub Actions 示例
- name: Terraform Plan
  run: |
    terraform init
    terraform plan -out=tfplan.binary
    terraform show -json tfplan.binary > tfplan.json

- name: Conftest
  run: conftest test -o table tfplan.json
```

## 远程策略库

Conftest 支持从远程拉取策略，方便组织级策略统一管理：

```bash
# 从 Git 仓库拉取策略
conftest test --update git::https://github.com/org/policy-library.git//policy tfplan.json

# 从 OCI 注册表拉取
conftest pull oci://registry.example.com/policies:latest
```

## 与其他工具的关系

| 工具 | 职责 |
|------|------|
| `terraform fmt` | 缩进、对齐、空白格式化 |
| `tflint` | 静态分析、废弃语法、命名规范 |
| `checkov` | 通用安全扫描（内置规则库） |
| `conftest` | 自定义策略检查（Rego）|
| `avmfix` | 属性排序、块排列、文件归位 |

---

## 动手实验

<KillercodaEmbed src="https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-tool-conftest" />
