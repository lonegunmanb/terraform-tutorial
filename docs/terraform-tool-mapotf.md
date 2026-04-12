---
order: 18
title: mapotf
group: 周边工具
group_order: 17
---

# mapotf：Terraform 元编程工具

[mapotf](https://github.com/Azure/mapotf)（MetA PrOgramming for TerraForm）是由微软 Azure 团队推出的开源工具，用于对 Terraform 配置进行**声明式的批量修改**。它的核心思想是：将 Terraform 配置视为可以被匹配和重写的对象，通过 `data` 块匹配目标、`transform` 块定义变更。

## 解决什么问题

`mapotf` 的应用场景很广，核心价值在于**对 Terraform 配置的声明式批量变更**。以下是几个典型痛点：

### ignore_changes 无法参数化

Terraform 的 `lifecycle` 块中 `ignore_changes` 不支持变量。这意味着第三方模块无法通过参数让用户定制哪些属性应被忽略。

考虑这样的场景：你使用社区 VPC 模块部署基础设施，但 AWS 运维策略会自动给所有 VPC 打上合规标签。每次 `terraform plan` 都会报告这些标签的 drift，因为模块内部的 `aws_vpc` 资源没有 `ignore_changes = [tags]`。你无法修改模块源码（那样会失去升级能力），Terraform 也不支持从外部传入 `ignore_changes`。`mapotf` 可以在不修改模块源码的前提下，动态为资源注入所需的 `ignore_changes`。

### Provider 大版本升级的自动化迁移

当 Provider 发布大版本更新（如 AzureRM 3.x → 4.x）时，往往引入大量破坏性变更——资源类型重命名、属性移除或拆分、默认值变化等。对于拥有几十甚至上百个模块的组织，手动逐个修改代码工作量巨大且容易遗漏。通过 `mapotf`，平台团队可以提前针对这些破坏性变更编写代码变换规则，用户只需运行一条命令即可自动完成迁移，无需手动逐一修改。

### 集中式治理

对于大规模使用 Terraform 模块的组织，平台团队需要统一执行某些策略——例如为所有模块注入遥测代码、统一 Provider 版本约束、为所有资源添加审计标签等。`mapotf` 允许将这些治理规则维护在中央 Git 仓库中，所有模块通过引用远程规则集一键应用，实现"一处更改，处处生效"。

## 安装

```bash
# Go install（需要 Go 1.21+）
go install github.com/Azure/mapotf@latest

# 验证
mapotf -h
```

## 核心概念

### data 块——匹配目标

`data` 块用于匹配 Terraform 配置中的特定元素。最常用的数据源是 `resource`，按资源类型匹配：

```hcl
data "resource" "all_vpcs" {
  resource_type = "aws_vpc"
}
```

匹配结果存储在 `data.resource.all_vpcs.result` 中，是一个以资源地址为 key 的 map。

### transform 块——定义变更

`transform` 块定义如何修改被匹配到的资源。最常用的转换类型是 `update_in_place`，它在原有配置基础上修改或添加属性：

```hcl
transform "update_in_place" "add_ignore_changes" {
  for_each             = data.resource.all_vpcs.result.aws_vpc
  target_block_address = each.value.mptf.block_address

  asstring {
    lifecycle {
      ignore_changes = "[\ntags, ${trimprefix(try(each.value.lifecycle.0.ignore_changes, "[\n]"), "[")}"
    }
  }
}
```

这段代码的关键在于**合并而非覆盖**：`try(each.value.lifecycle.0.ignore_changes, "[\n]")` 读取资源现有的 `ignore_changes` 列表，`trimprefix(..., "[")` 去掉开头的 `[`，然后在前面追加 `tags,`。如果资源没有 `ignore_changes`，`try` 回退到 `"[\n]"`，去掉 `[` 后只剩 `\n]`，最终结果为 `[\ntags, \n]` 即 `[tags]`。

### asstring 块

`asstring` 块内的值会以**原始字符串**形式写入 HCL 文件。这对于 `ignore_changes` 这类需要写入字面量列表（而非 HCL 表达式）的场景至关重要。

## 工作流

`mapotf` 本质上是一个 **Terraform 的包装器（wrapper）**——你可以直接用 `mapotf` 替代 `terraform` 来执行所有常用子命令。它会在执行 Terraform 命令前自动应用转换规则，执行完成后自动还原，对原始代码零侵入。

### 作为 Terraform wrapper 使用

```bash
# 等同于 terraform init（直接透传，不执行转换）
mapotf init --mptf-dir ./mptf-rules --tf-dir .

# 先转换 → terraform plan → 自动还原
mapotf plan --mptf-dir ./mptf-rules --tf-dir .

# 先转换 → terraform apply → 自动还原
mapotf apply --mptf-dir ./mptf-rules --tf-dir .

# 不认识的参数自动透传给 terraform
mapotf apply --mptf-dir ./mptf-rules --tf-dir . -auto-approve
```

### -r 参数：递归转换第三方模块

默认情况下，`mapotf` 只转换 `--tf-dir` 指定目录中的 `.tf` 文件。但第三方模块下载后存放在 `.terraform/modules/` 子目录中——如果不递归进去，就无法修改模块内部的资源定义。

`-r`（`--recursive`）参数让 `mapotf` 递归扫描所有子目录（包括 `.terraform/modules/`），这样就能对第三方模块中的资源应用转换规则：

```bash
# 递归转换，包括 .terraform/modules/ 中的第三方模块代码
mapotf plan -r --mptf-dir ./mptf-rules --tf-dir .
mapotf apply -r --mptf-dir ./mptf-rules --tf-dir . -auto-approve
```

这正是解决"无法定制第三方模块中资源的 `ignore_changes`"这一痛点的关键——`-r` 让 `mapotf` 深入到 `terraform init` 下载的模块源码中执行转换。由于 wrapper 模式下转换是临时的（执行后自动还原），模块源码不会被永久修改，下次 `terraform init -upgrade` 更新模块版本也不受影响。

不同子命令的处理方式：

| 子命令 | 是否先执行转换 | 说明 |
|--------|:---:|------|
| `plan` / `apply` / `destroy` | ✅ | 转换 → 执行 → 还原 |
| `validate` / `console` / `import` | ✅ | 转换 → 执行 → 还原 |
| `refresh` / `show` / `state` / `test` / `graph` | ✅ | 转换 → 执行 → 还原 |
| `init` / `fmt` / `get` / `version` / `workspace` | ❌ | 直接透传，不转换 |

### transform 模式——仅修改文件

如果只想查看转换效果而不执行 Terraform，使用 `transform` 子命令：

```bash
mapotf transform --mptf-dir ./mptf-rules --tf-dir .
```

1. 读取 `--mptf-dir` 中的规则文件
2. 扫描 `--tf-dir` 中的 `.tf` 文件
3. 匹配 `data` 块定义的目标
4. 应用 `transform` 块定义的变更
5. 修改 `.tf` 文件，并生成 `.tf.mptfbackup` 备份

之后可以用 `diff` 审查变更，确认无误后手动 `terraform plan/apply`。使用 `mapotf reset` 可还原文件，`mapotf clean-backup` 清理备份。

### 其他命令

| 命令 | 说明 |
|------|------|
| `mapotf transform` | 仅转换，不执行 Terraform，生成 `.mptfbackup` 备份 |
| `mapotf plan` | 转换 → `terraform plan` → 还原 |
| `mapotf apply` | 转换 → `terraform apply` → 还原 |
| `mapotf reset` | 从备份还原所有文件 |
| `mapotf clean-backup` | 清理 `.mptfbackup` 备份文件 |

## 实际应用场景

### 为第三方模块中的资源添加 ignore_changes

这是 `mapotf` 最典型的用例。假设使用 `terraform-aws-modules/vpc/aws` 模块，需要忽略 VPC 的 `tags` 漂移：

```hcl
# mptf-rules/ignore_vpc_tags.mptf.hcl

data "resource" "vpc" {
  resource_type = "aws_vpc"
}

transform "update_in_place" "ignore_vpc_tags" {
  for_each             = try(data.resource.vpc.result.aws_vpc, {})
  target_block_address = each.value.mptf.block_address

  asstring {
    lifecycle {
      ignore_changes = "[\ntags, tags_all, ${trimprefix(try(each.value.lifecycle.0.ignore_changes, "[\n]"), "[")}"
    }
  }
}
```

注意这里使用了合并写法（和前面核心概念中介绍的一样），不会覆盖资源已有的 `ignore_changes`。

### 集中式治理

对于大规模使用 Terraform 模块的组织，平台团队需要统一执行某些策略——例如为所有模块注入遥测代码、统一 Provider 版本约束、为所有资源添加审计标签等。`mapotf` 允许将这些治理规则维护在中央 Git 仓库中，所有模块通过引用远程规则集一键应用，实现"一处更改，处处生效"。

Azure Verified Modules (AVM) 项目就是一个真实的大规模治理案例。AVM 团队在 [avm-terraform-governance](https://github.com/Azure/avm-terraform-governance) 仓库中维护了一组 `mapotf` 规则，通过 pre-commit 钩子自动应用到数百个模块仓库：

- [**required_provider_versions.mptf.hcl**](https://github.com/Azure/avm-terraform-governance/blob/main/mapotf-configs/pre-commit/required_provider_versions.mptf.hcl) — 统一规定 AzAPI Provider 最低版本为 `~> 2.4`、Random Provider 为 `~> 3.0`，使用 `semvercheck` 函数检测当前版本约束是否满足，不满足则自动更新 `required_providers` 块
- [**main_telemetry_tf.mptf.hcl**](https://github.com/Azure/avm-terraform-governance/blob/main/mapotf-configs/pre-commit/main_telemetry_tf.mptf.hcl) — 为每个模块自动注入遥测代码（`modtm_telemetry` 资源、`random_uuid`、`modtm_module_source` 数据源等），让微软可以匿名统计模块使用情况。当遥测机制需要调整时，只需更新这一个规则文件，所有模块在下次 pre-commit 时自动获取最新逻辑
- [**avm_headers_for_azapi.mptf.hcl**](https://github.com/Azure/avm-terraform-governance/blob/main/mapotf-configs/pre-commit/avm_headers_for_azapi.mptf.hcl) — 为所有 `azapi_resource` 和 `azapi_update_resource` 的 `create_headers`/`read_headers`/`update_headers`/`delete_headers` 注入 AVM 标识头，让 Azure API 知道请求来自哪个 AVM 模块

这些规则集中维护在一个 Git 仓库，各模块在 pre-commit 时通过远程 URL 引用：

```bash
mapotf transform \
  --mptf-dir git::https://github.com/Azure/avm-terraform-governance.git//mapotf-configs/pre-commit \
  --tf-dir .
```

### 批量 Provider 升级

当 Provider 大版本更新引入不兼容变更时，`mapotf` 可以自动重构配置：

```bash
mapotf transform \
  --mptf-dir git::https://github.com/lonegunmanb/TerraformConfigWelder.git//azurerm/v3_v4 \
  --tf-dir .
```

## 规则文件格式

- 规则文件使用 `.mptf.hcl` 扩展名
- 使用标准 HCL 语法，支持 `locals`、`variable`、Terraform 内置函数
- `data` 块的 `result` 是一个嵌套 map：`data.resource.<name>.result.<resource_type>.<resource_name>`
- 每个匹配到的资源包含一个特殊属性 `mptf.block_address`，用于 `target_block_address`

## 与 hcledit 的对比

| 对比 | mapotf | hcledit |
|------|--------|---------|
| 匹配方式 | 声明式（按资源类型、属性等） | 命令式（按地址路径） |
| 批量操作 | 内置 for_each | 需要外部循环 |
| 规则复用 | 支持远程 Git 仓库 | 不支持 |
| 适用场景 | 模块治理、ignore_changes 定制 | 简单的单属性读写 |
| 学习曲线 | 需要理解 data/transform 模型 | 直接操作 |

---

## 动手实验

<KillercodaEmbed src="https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-tool-mapotf" />
