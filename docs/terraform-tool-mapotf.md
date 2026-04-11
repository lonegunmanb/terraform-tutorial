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
mapotf version
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
      ignore_changes = "[tags]"
    }
  }
}
```

### asstring 块

`asstring` 块内的值会以**原始字符串**形式写入 HCL 文件。这对于 `ignore_changes` 这类需要写入字面量列表（而非 HCL 表达式）的场景至关重要。

## 工作流

`mapotf` 提供两种执行模式：

### transform 模式——仅修改文件

```bash
mapotf transform --mptf-dir ./mptf-rules --tf-dir .
```

1. 读取 `--mptf-dir` 中的规则文件
2. 扫描 `--tf-dir` 中的 `.tf` 文件
3. 匹配 `data` 块定义的目标
4. 应用 `transform` 块定义的变更
5. 修改 `.tf` 文件，并生成 `.tf.mptfbackup` 备份

之后可以用 `diff` 审查变更，确认无误后手动 `terraform plan/apply`。

### apply 模式——修改 + 执行 + 还原

```bash
mapotf apply --mptf-dir ./mptf-rules --tf-dir .
```

1. 备份 `.tf` 文件
2. 应用转换规则
3. 自动执行 `terraform apply`
4. **还原** `.tf` 文件到原始状态

这种模式适合 CI/CD，修改是临时的——只在 apply 期间生效，执行完自动恢复。

### 其他命令

| 命令 | 说明 |
|------|------|
| `mapotf transform` | 仅转换，不执行 Terraform |
| `mapotf apply` | 转换 + apply + 还原 |
| `mapotf plan` | 转换 + plan + 还原 |
| `mapotf reset` | 从备份还原所有文件 |
| `mapotf clean-backup` | 清理备份文件 |

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
      ignore_changes = "[tags, tags_all]"
    }
  }
}
```

### 保留已有的 ignore_changes

如果资源已经有 `ignore_changes`，需要合并而非覆盖：

```hcl
transform "update_in_place" "merge_ignore_changes" {
  for_each             = try(data.resource.vpc.result.aws_vpc, {})
  target_block_address = each.value.mptf.block_address

  asstring {
    lifecycle {
      ignore_changes = "[\ntags, tags_all, ${trimprefix(try(each.value.lifecycle.0.ignore_changes, "[\n]"), "[")}"
    }
  }
}
```

这段代码先读取资源现有的 `ignore_changes` 列表，去掉开头的 `[`，然后在前面追加 `tags, tags_all`。

### 集中式治理

平台团队可以维护远程 Git 仓库中的规则，所有项目通过 URL 引用：

```bash
mapotf transform \
  --mptf-dir git::https://github.com/your-org/terraform-rules.git//vpc-tags \
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
