---
order: 91
title: init
group: Terraform CLI
group_order: 9
---

# terraform init

`terraform init` 是 Terraform 工作流的起点，用于初始化包含 Terraform 代码的工作目录。在以下场景中必须运行该命令：

- 首次克隆或创建 Terraform 项目
- 添加、修改或删除 Provider
- 修改模块引用
- 切换 Backend 配置

反复执行 `terraform init` 是安全的——即使某些步骤出错，该命令也不会删除资源或状态文件。

## 用法

```bash
terraform init [options]
```

## 主要步骤

`terraform init` 会依次执行以下三步：

1. **Backend 初始化**：读取代码中的 `backend` 块，初始化状态存储。若未配置，则使用本地文件 Backend（`terraform.tfstate`）。
2. **子模块安装**：解析所有 `module` 块，下载引用的模块代码到 `.terraform/modules/`。
3. **Provider 插件安装**：根据 `required_providers` 块下载所需的 Provider 插件到 `.terraform/providers/`。

完成后，工作目录中会新增两个文件/目录：

| 路径 | 作用 |
|------|------|
| `.terraform/` | 缓存目录，存放下载的 Provider 插件和模块代码 |
| `.terraform.lock.hcl` | 依赖锁文件，固定 Provider 版本和校验和 |

`.terraform.lock.hcl` 应纳入版本控制；`.terraform/` 通常通过 `.gitignore` 排除。

## 常用参数

### -upgrade

升级所有已安装的插件和模块到满足版本约束的最新版本，并更新锁文件：

```bash
terraform init -upgrade
```

### -reconfigure

重置 Backend 配置，忽略已有配置，不迁移现有状态。适用于切换 Backend 但不需要保留旧状态的场景：

```bash
terraform init -reconfigure
```

### -migrate-state 与 -force-copy

切换 Backend 时，`terraform init` 会以交互式询问的方式确认是否将现有状态复制到新 Backend：

```bash
terraform init
```

如果需要跳过交互式确认（如 CI/CD 场景），可以使用 `-force-copy`（相当于自动回答 yes）：

```bash
terraform init -force-copy
```

`-migrate-state` 是等效的别名，效果与 `-force-copy` 相同：

```bash
terraform init -migrate-state
```

### -backend-config

动态传入 Backend 配置（部分配置模式），适用于需要运行时注入敏感参数的 CI/CD 场景：

```bash
terraform init \
  -backend-config="bucket=my-bucket" \
  -backend-config="key=prod/state.tfstate"
```

对应代码中使用空 `backend` 块：

```hcl
terraform {
  backend "s3" {}
}
```

### -lockfile=readonly

禁止更新锁文件，仅验证已记录的校验和。适合在 CI/CD 管道中确保不会意外修改锁文件：

```bash
terraform init -lockfile=readonly
```

::: warning
`-lockfile=readonly` 与 `-upgrade` 互不兼容。
:::

### -get=false

跳过子模块的下载步骤。仅在模块已安装的情况下使用：

```bash
terraform init -get=false
```

### -input=false

禁止交互式输入提示，适用于自动化环境：

```bash
terraform init -input=false
```

## Provider 依赖锁文件

`.terraform.lock.hcl` 由 `terraform init` 自动生成并维护，记录了：

- 使用的 Provider 来源（如 `registry.terraform.io/hashicorp/aws`）
- 具体版本号（满足 `version` 约束的版本）
- Provider 二进制文件在多个平台（Linux/macOS/Windows）的 SHA-256 哈希值

**最佳实践：** 将 `.terraform.lock.hcl` 提交到代码仓库，以确保团队成员和 CI/CD 流水线使用完全相同的 Provider 版本。

```hcl
# .terraform.lock.hcl（自动生成，勿手动编辑）
provider "registry.terraform.io/hashicorp/aws" {
  version     = "5.82.2"
  constraints = "~> 5.0"
  hashes = [
    "h1:AbcXyz...",
    ...
  ]
}
```

## Backend 初始化与切换

如果代码中包含 `backend` 块，`terraform init` 会初始化对应的远程状态存储。

当修改了已有的 Backend 配置时，必须明确告知 Terraform 如何处理现有状态：

| 参数 | 行为 |
|------|------|
| 不加参数 | 交互式询问是否将已有状态复制到新 Backend |
| `-force-copy` / `-migrate-state` | 跳过交互式确认，自动将已有状态复制到新 Backend |
| `-reconfigure` | 忽略已有状态，直接切换到新 Backend 配置 |

不加任何参数时，若检测到有已有状态可以迁移，Terraform 会交互式询问：

```
Do you want to copy existing state to the new backend?
  ...
  Enter a value: yes
```

## 在自动化环境中运行

在 CI/CD 管道中推荐以下组合：

```bash
terraform init -input=false -lockfile=readonly
```

- `-input=false`：禁用交互式输入（CI 中无法交互）
- `-lockfile=readonly`：防止 CI 意外修改锁文件

<KillercodaEmbed src="https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-cli-init" />
