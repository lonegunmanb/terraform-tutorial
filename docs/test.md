---
order: 16
title: Terraform 测试
---

# Terraform 测试

Terraform 自 v1.6.0 起引入了原生测试框架，让模块作者可以验证配置的正确性，而不会影响现有基础设施或状态文件。测试使用专用的 `.tftest.hcl` 文件编写，通过 `terraform test` 命令执行。

本章将系统介绍 Terraform 测试框架的核心机制：

## 目录

- [测试框架概览](#测试框架概览) — 测试文件结构与执行流程
- [run 块](#run-块) — 测试执行的基本单元
- [断言 (assert)](#断言-assert) — 验证配置的正确性
- [变量](#变量) — 在测试中传递和覆盖变量
- [辅助模块](#辅助模块) — 使用 module 块加载测试专用模块
- [期望失败 (expect_failures)](#期望失败-expect_failures) — 测试错误分支
- [Mock 与 Override](#mock-与-override) — 模拟 Provider 和资源（v1.7.0+）
- [terraform test 命令](#terraform-test-命令) — CLI 选项与输出格式

---

## 测试框架概览

### 测试文件发现

Terraform 根据文件扩展名发现测试文件：`.tftest.hcl` 或 `.tftest.json`。默认搜索位置：

1. **根配置目录**（运行 `terraform test` 的目录）
2. **`tests/` 子目录**

可通过 `-test-directory` 参数修改搜索目录。

推荐的项目结构：

```
project/
├── main.tf
├── variables.tf
├── outputs.tf
├── tests/
│   ├── basic.tftest.hcl
│   ├── validation.tftest.hcl
│   └── setup/
│       └── main.tf          # 辅助模块
```

### 测试文件结构

每个测试文件可以包含：

- 零到一个 `test` 块（配置测试行为，如并行执行）
- 一到多个 `run` 块（测试执行的基本单元）
- 零到一个 `variables` 块（文件级别的变量值）
- 零到多个 `provider` 块（覆盖 Provider 配置）

```hcl
# basic.tftest.hcl

variables {
  bucket_prefix = "test"
}

run "check_bucket_name" {
  command = plan

  assert {
    condition     = aws_s3_bucket.app.bucket == "test-bucket"
    error_message = "S3 桶名不符合预期"
  }
}
```

### 集成测试 vs 单元测试

Terraform 测试支持两种模式：

| 模式 | command 值 | 行为 | 类比 |
|------|-----------|------|------|
| 集成测试 | `apply`（默认） | 创建真实基础设施，验证后销毁 | Integration Test |
| 单元测试 | `plan` | 仅执行 plan，不创建资源 | Unit Test |

使用 `command = plan` 时，Terraform 不会创建任何资源，适合验证配置逻辑（命名规则、标签计算等）。使用 `command = apply`（默认值）时，Terraform 会创建临时资源，测试结束后自动销毁。

### 状态管理

测试执行时，Terraform 在内存中维护独立的状态文件，与现有基础设施状态完全隔离。每个测试文件至少有一个主状态文件，加载辅助模块时会创建额外的状态文件。测试结束后，Terraform 按照 `run` 块的逆序销毁所有创建的资源。

---

## run 块

`run` 块是测试执行的基本单元。每个 `run` 块模拟一次 `terraform plan` 或 `terraform apply` 操作。Terraform 按顺序执行 `run` 块，后续的 `run` 块可以引用前面 `run` 块的输出。

### 基本属性

| 属性 | 说明 | 默认值 |
|------|------|--------|
| `command` | 执行 `plan` 还是 `apply` | `apply` |
| `plan_options.mode` | 计划模式：`normal` 或 `refresh-only` | `normal` |
| `plan_options.refresh` | 是否刷新状态 | `true` |
| `plan_options.replace` | 强制重建的资源地址列表 | — |
| `plan_options.target` | 定向操作的资源地址列表 | — |
| `variables` | run 块级别的变量覆盖 | — |
| `module` | 加载辅助模块替代主配置 | — |
| `providers` | 自定义 Provider 映射 | — |
| `assert` | 断言块 | — |
| `expect_failures` | 期望失败的可检查对象列表 | — |

### 示例

```hcl
run "create_s3_bucket" {
  command = apply

  variables {
    bucket_name = "my-test-bucket"
  }

  assert {
    condition     = aws_s3_bucket.app.bucket == "my-test-bucket"
    error_message = "桶名不正确"
  }
}

run "verify_output" {
  command = plan

  assert {
    condition     = output.bucket_name == "my-test-bucket"
    error_message = "输出值不正确"
  }
}
```

第一个 `run` 块使用 `apply` 创建 S3 桶，第二个 `run` 块使用 `plan` 验证输出值。由于 Terraform 按顺序执行，第二个 `run` 块可以看到第一个 `run` 块创建的资源状态。

---

## 断言 (assert)

每个 `run` 块可以包含多个 `assert` 块。`assert` 块包含两个参数：

- **`condition`** — 布尔表达式，为 `true` 时断言通过
- **`error_message`** — 断言失败时显示的错误信息

```hcl
run "check_tags" {
  command = plan

  assert {
    condition     = aws_s3_bucket.app.tags["Environment"] == "dev"
    error_message = "Environment 标签应为 dev"
  }

  assert {
    condition     = aws_s3_bucket.app.tags["ManagedBy"] == "Terraform"
    error_message = "ManagedBy 标签应为 Terraform"
  }
}
```

### 断言中的引用

断言可以引用主配置中的所有命名值（资源、数据源、变量、局部值等），还可以引用当前和之前 `run` 块的输出：

```hcl
run "setup" {
  # 创建资源...
}

run "verify" {
  command = plan

  assert {
    # 引用前一个 run 块的输出
    condition     = run.setup.bucket_id != ""
    error_message = "setup 阶段未返回 bucket_id"
  }
}
```

::: tip 一个 run 块中放多少断言？
每个 `run` 块都会执行一次 `plan` 或 `apply`。如果多个断言验证的是**同一次操作的不同方面**，放在同一个 `run` 块中更高效。如果断言依赖不同的操作（不同变量、不同状态），则应拆分为多个 `run` 块。
:::

---

## 变量

测试文件支持在两个层级定义变量值：

### 文件级变量

文件级 `variables` 块的值传递给该文件中所有 `run` 块：

```hcl
variables {
  environment = "test"
  app_name    = "myapp"
}

run "default_values" {
  command = plan
  # 使用文件级变量 environment="test", app_name="myapp"
}
```

### run 块级变量

`run` 块内的 `variables` 块可以覆盖文件级变量：

```hcl
variables {
  bucket_prefix = "test"
}

run "uses_root_level_value" {
  command = plan

  assert {
    condition     = aws_s3_bucket.app.bucket == "test-bucket"
    error_message = "桶名不符合预期"
  }
}

run "overrides_root_level_value" {
  command = plan

  variables {
    bucket_prefix = "staging"
  }

  assert {
    condition     = aws_s3_bucket.app.bucket == "staging-bucket"
    error_message = "桶名不符合预期"
  }
}
```

### 变量引用

`run` 块中的变量可以引用前一个 `run` 块的输出：

```hcl
run "setup" {
  module {
    source = "./tests/setup"
  }
}

run "use_setup_output" {
  variables {
    bucket_name = run.setup.bucket_name
  }
}
```

### 优先级

测试文件中定义的变量具有最高优先级，覆盖环境变量、`.tfvars` 文件和命令行 `-var` 参数。

---

## 辅助模块

通过 `run` 块的 `module` 属性，可以加载辅助模块替代主配置执行。常见用途：

1. **Setup 模块** — 在测试前创建前置资源（如 S3 桶、网络等）
2. **Loader 模块** — 通过数据源验证主配置创建的资源

### 示例：Setup + 主配置 + Verify

```hcl
# tests/bucket.tftest.hcl

variables {
  bucket = "test-bucket"
}

run "setup" {
  # 加载辅助模块创建 S3 桶
  module {
    source = "./tests/setup"
  }
}

run "execute" {
  # 使用辅助模块创建的桶，执行主配置
  variables {
    bucket_name = run.setup.bucket_name
  }
}

run "verify" {
  # 加载验证模块检查结果
  module {
    source = "./tests/loader"
  }

  assert {
    condition     = length(data.aws_s3_objects.objects.keys) == 2
    error_message = "创建的 S3 对象数量不正确"
  }
}
```

::: warning 辅助模块的状态
每个辅助模块有独立的状态文件。Terraform 在测试结束后按 `run` 块逆序销毁资源。如果模块之间有依赖关系（如先创建桶、再上传文件），需要注意销毁顺序。
:::

---

## 期望失败 (expect_failures)

测试不仅要验证"正确的输入产生正确的结果"，还要验证"错误的输入被正确拒绝"。`expect_failures` 属性用于声明哪些可检查对象应当失败：

```hcl
# main.tf
variable "port" {
  type = number

  validation {
    condition     = var.port > 0 && var.port <= 65535
    error_message = "端口号必须在 1-65535 之间"
  }
}
```

```hcl
# tests/validation.tftest.hcl

run "valid_port" {
  command = plan

  variables {
    port = 8080
  }

  # 正常断言，验证合法值被接受
}

run "invalid_port" {
  command = plan

  variables {
    port = -1
  }

  # 期望变量校验失败
  expect_failures = [
    var.port,
  ]
}
```

`expect_failures` 支持的可检查对象：资源、数据源、check 块、输入变量、输出值。

::: warning 与 command = apply 组合使用
`expect_failures` 最适合与 `command = plan` 搭配。如果在 `command = apply` 的 `run` 块中使用，当自定义条件在 plan 阶段就失败时，整个 `run` 块会报错（因为 apply 无法执行）。
:::

---

## Mock 与 Override

自 Terraform v1.7.0 起，测试框架支持模拟（Mock）Provider 和覆盖（Override）特定资源，无需真实的云凭据即可运行测试。

### Mock Provider

`mock_provider` 块创建一个模拟的 Provider，返回与真实 Provider 相同的 Schema，但不会调用任何 API：

```hcl
# mock_test.tftest.hcl

mock_provider "aws" {}

run "check_bucket_name" {
  variables {
    bucket_name = "my-bucket"
  }

  assert {
    condition     = aws_s3_bucket.app.bucket == "my-bucket"
    error_message = "桶名不正确"
  }
}
```

Mock Provider 对计算属性自动生成假数据：

- 数字 → `0`
- 布尔 → `false`
- 字符串 → 随机 8 字符字母数字串
- 集合 → 空集合

可通过 `mock_resource` 和 `mock_data` 块指定默认值：

```hcl
mock_provider "aws" {
  mock_resource "aws_s3_bucket" {
    defaults = {
      arn = "arn:aws:s3:::test-bucket"
    }
  }
}
```

### Override 块

Override 块可以覆盖特定资源、数据源或模块的值，无论底层 Provider 是真实的还是 Mock 的：

| 块类型 | 用途 | 参数 |
|--------|------|------|
| `override_resource` | 覆盖资源属性 | `target`、`values` |
| `override_data` | 覆盖数据源属性 | `target`、`values` |
| `override_module` | 覆盖模块输出 | `target`、`outputs` |

```hcl
mock_provider "aws" {}

override_resource {
  target = aws_instance.api
}

override_data {
  target = data.aws_ami.ubuntu
  values = {
    id = "ami-12345678"
  }
}

run "check_instance" {
  assert {
    condition     = aws_instance.api.ami == "ami-12345678"
    error_message = "AMI 不正确"
  }
}
```

Override 块可以定义在测试文件根级别（作用于所有 `run` 块），也可以定义在 `run` 块内部（仅作用于该 `run` 块，且优先级更高）。

---

## terraform test 命令

### 基本用法

```bash
# 运行所有测试
terraform test

# 只运行指定测试文件
terraform test -filter=tests/basic.tftest.hcl

# 输出详细的 plan/state 信息
terraform test -verbose

# JSON 格式输出
terraform test -json

# 生成 JUnit XML 报告
terraform test -junit-xml=report.xml

# 指定测试目录
terraform test -test-directory=testing
```

### 常用选项

| 选项 | 说明 |
|------|------|
| `-filter=FILE` | 只运行指定测试文件 |
| `-verbose` | 输出每个 run 块的 plan 或 state 详情 |
| `-json` | 机器可读的 JSON 输出 |
| `-junit-xml=FILE` | 保存 JUnit XML 格式报告 |
| `-test-directory=DIR` | 指定测试文件目录（默认 `tests`） |

### 执行流程

`terraform test` 的完整执行流程：

1. 在根目录和 `tests/` 目录中搜索 `.tftest.hcl` 文件
2. 对每个测试文件，按顺序执行 `run` 块
3. 每个 `run` 块执行 `plan` 或 `apply`，然后运行断言
4. 所有 `run` 块执行完毕后，按逆序销毁所有创建的资源
5. 报告测试结果

::: tip 测试不影响现有状态
`terraform test` 在内存中维护独立的状态，与 `terraform.tfstate` 完全隔离。你可以放心运行测试而不会影响任何现有基础设施。
:::

### 🧪 动手实验

<KillercodaEmbed src="https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-test" />
