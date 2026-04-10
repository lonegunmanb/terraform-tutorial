---
order: 101
title: workspace
group: Terraform CLI
group_order: 9
---

# terraform workspace

`terraform workspace` 管理同一工作目录下的多个 **状态实例**（workspace）。每个 workspace 拥有独立的 state，使你能用同一套配置管理多组互不重叠的基础设施。

::: danger CLI workspace ≠ HCP Terraform / Terraform Cloud workspace
这两个"workspace"是**完全不同的概念**，切勿混淆：

| | CLI workspace | HCP Terraform workspace |
|---|---|---|
| 本质 | 同一工作目录下的**多份 state** | 独立的**工作目录**，各有自己的配置、变量、state、运行历史 |
| 配置 | 所有 workspace 共享同一份 `.tf` 文件 | 每个 workspace 关联独立的 Terraform 配置（可以来自不同仓库或分支） |
| 变量 | 需要在代码中用 `terraform.workspace` 或条件表达式区分 | 每个 workspace 有独立的变量值设置界面 |
| 后端凭证 | 所有 workspace 共享同一个 backend 及其凭证 | 每个 workspace 可以配置独立的凭证和访问控制 |
| 典型用途 | 快速创建临时环境（如功能分支测试） | 正式管理 dev / staging / prod 等长期环境 |
| 隔离程度 | 弱——仅 state 隔离，backend 和凭证共享 | 强——配置、变量、凭证、权限全部独立 |

**结论**：CLI workspace 适合单人快速创建临时副本（如测试分支）。对于需要不同凭证、不同访问控制的多环境管理（dev/staging/prod），应使用 HCP Terraform workspace 或为每个环境创建独立的 Terraform 配置目录。
:::

## 子命令一览

```bash
terraform workspace <subcommand> [options] [args]
```

| 子命令 | 说明 |
|--------|------|
| `show` | 显示当前所在的 workspace 名称 |
| `list` | 列出所有 workspace，当前 workspace 以 `*` 标记 |
| `new` | 创建新 workspace 并切换到该 workspace |
| `select` | 切换到已有的 workspace |
| `delete` | 删除指定 workspace |

## terraform workspace show

显示当前使用的 workspace 名称：

```bash
terraform workspace show
```

输出示例：

```
default
```

每个初始化过的工作目录都自带一个名为 `default` 的默认 workspace。

## terraform workspace list

列出当前工作目录中所有 workspace，用 `*` 标记当前 workspace：

```bash
terraform workspace list
```

输出示例：

```
  default
* dev
  staging
```

## terraform workspace new

创建新 workspace 并自动切换过去：

```bash
terraform workspace new [OPTIONS] NAME
```

创建后立即切换到新 workspace，此时 state 是空的——即使 default workspace 里已经有资源，新 workspace 也看不到。

可选参数：

| 参数 | 说明 |
|------|------|
| `-state=PATH` | 用已有的 state 文件初始化新 workspace |
| `-lock=false` | 不锁定 state（多人协作时有风险） |
| `-lock-timeout=DURATION` | 等待 state 锁的超时时间，默认 `0s` |

```bash
# 创建名为 dev 的 workspace
terraform workspace new dev

# 从已有 state 文件创建
terraform workspace new -state=old.terraform.tfstate recovery
```

## terraform workspace select

切换到已有的 workspace：

```bash
terraform workspace select [OPTIONS] NAME
```

切换后，后续所有命令（plan、apply、destroy 等）都在该 workspace 的 state 上操作。

| 参数 | 说明 |
|------|------|
| `-or-create` | 如果目标 workspace 不存在则自动创建，默认 `false` |

```bash
terraform workspace select dev
terraform workspace select -or-create staging
```

## terraform workspace delete

删除指定 workspace：

```bash
terraform workspace delete [OPTIONS] NAME
```

删除限制：

- 不能删除当前所在的 workspace——需先切换到其他 workspace
- 不能删除仍在追踪资源的 workspace——需先 `terraform destroy`

| 参数 | 说明 |
|------|------|
| `-force` | 强制删除仍有资源的 workspace（资源变成无人管理的"悬空资源"） |
| `-lock=false` | 不锁定 state |
| `-lock-timeout=DURATION` | 等待 state 锁的超时时间 |

```bash
terraform workspace delete staging
terraform workspace delete -force abandoned-env
```

::: warning
`-force` 删除仍有资源的 workspace 后，这些资源将变成"悬空资源"——它们仍然存在于云端，但 Terraform 不再管理。除非你确实打算停止用 Terraform 管理这些资源，否则请先 `terraform destroy` 再删除 workspace。
:::

## terraform.workspace 变量

在 `.tf` 配置中，可以通过内置变量 `terraform.workspace` 获取当前 workspace 名称，用于区分不同环境的资源：

```hcl
locals {
  env = terraform.workspace
}

resource "aws_s3_bucket" "data" {
  bucket = "myapp-${local.env}-data"
}
```

当你在 `dev` workspace 中 apply 时，桶名为 `myapp-dev-data`；切到 `staging` 后 apply，桶名为 `myapp-staging-data`。同一份配置，不同 workspace 产生不同的资源——这就是 CLI workspace 的核心机制。

## Workspace 的状态存储

### 本地 Backend

使用本地 state 时，Terraform 的存储结构如下：

- `default` workspace 的 state → `terraform.tfstate`（根目录）
- 其他 workspace 的 state → `terraform.tfstate.d/<NAME>/terraform.tfstate`

```
.
├── terraform.tfstate              # default workspace
├── terraform.tfstate.d/
│   ├── dev/
│   │   └── terraform.tfstate      # dev workspace
│   └── staging/
│       └── terraform.tfstate      # staging workspace
```

### 远程 Backend

远程 backend（如 S3、Consul）会在 state 路径中追加 workspace 名称。具体格式取决于 backend 类型。

## 适用场景与限制

### 推荐使用

- 功能分支对应临时测试环境——开分支时创建 workspace，合并后销毁并删除
- 快速验证配置变更——在独立 workspace 中 apply 测试，不影响主环境

### 不推荐使用

- 需要不同 IAM 角色/凭证管理不同环境（dev/staging/prod）
- 需要不同团队独立管理各自的基础设施组件
- 需要严格的访问控制和审计隔离

对于这些场景，应使用独立的 Terraform 配置目录（每个环境一个 backend）或 HCP Terraform workspace。

<KillercodaEmbed src="https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-cli-workspace" />
