---
order: 90
title: CLI 配置文件
group: Terraform CLI
group_order: 9
---

# Terraform CLI 配置文件

Terraform CLI 的行为可以通过一个**用户级别的配置文件**进行定制。这个配置文件独立于任何基础设施配置（`.tf` 文件），作用于当前用户的所有 Terraform 工作目录。

本章将介绍 CLI 配置文件的位置、语法和主要配置项。

## 配置文件位置

| 操作系统 | 文件名 | 位置 |
|---------|--------|------|
| Linux / macOS | `.terraformrc` | 用户主目录 `~/.terraformrc` |
| Windows | `terraform.rc` | `%APPDATA%` 目录 |

可通过环境变量 `TF_CLI_CONFIG_FILE` 指定自定义路径，文件名应遵循 `*.tfrc` 模式：

```bash
export TF_CLI_CONFIG_FILE="$HOME/custom.tfrc"
```

::: tip
`TF_CLI_CONFIG_FILE` 在需要区分不同项目的 CLI 配置（如 Provider 开发场景）时非常有用。
:::

## 配置文件语法

CLI 配置文件使用与 `.tf` 文件相同的 **HCL 语法**，但可用的属性和块不同。一个最小的配置示例：

```hcl
plugin_cache_dir   = "$HOME/.terraform.d/plugin-cache"
disable_checkpoint = true
```

## Provider Plugin Cache

默认情况下，`terraform init` 会为每个工作目录单独下载 Provider 插件。如果有多个配置使用同一个 Provider，插件会被重复下载。

Provider 插件通常体积较大（数百 MB），对于网络较慢或有流量限制的环境，可以启用**插件缓存**，让同一版本的插件只下载一次：

```hcl
plugin_cache_dir = "$HOME/.terraform.d/plugin-cache"
```

::: warning
缓存目录必须事先创建，Terraform 不会自动创建它。
:::

也可以通过环境变量设置：

```bash
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"
```

### 工作原理

启用缓存后，`terraform init` 的行为变为：

1. 正常查询 Registry 获取可用版本的元数据
2. 选定版本后，先检查缓存目录中是否已有该版本
3. 如果已缓存，直接从缓存复制（或创建符号链接）到工作目录
4. 如果未缓存，先下载到缓存，再从缓存复制到工作目录

::: info 注意事项
- Terraform 不会自动清理缓存中的旧版本，需要手动删除
- 缓存目录不能同时作为 `filesystem_mirror` 目录
- 缓存目录的并发安全性没有保证，避免多个 `terraform init` 同时写入
:::

## Checkpoint 控制

Terraform 默认会联系 HashiCorp 的 [Checkpoint](https://checkpoint.hashicorp.com/) 服务，检查版本更新和安全公告。发送的数据不包含用户身份信息。

在离线环境或安全策略严格的场景下，可以关闭：

```hcl
# 完全禁用 Checkpoint（不联网检查版本和安全公告）
disable_checkpoint = true

# 仍然检查更新，但不发送匿名去重 ID
disable_checkpoint_signature = true
```

也可以通过环境变量禁用：

```bash
export CHECKPOINT_DISABLE=1
```

## Provider Installation

`provider_installation` 块可以自定义 `terraform init` 安装 Provider 插件的方式。默认行为是从 Provider 的源 Registry（通常是 `registry.terraform.io`）直接下载，但在防火墙受限或离线环境中需要替代方案。

### 安装方法

| 方法 | 说明 |
|------|------|
| `direct` | 从源 Registry 直接下载（默认行为） |
| `filesystem_mirror` | 从本地文件系统目录中查找 |
| `network_mirror` | 从 HTTPS 镜像服务器下载 |

### 混合配置示例

```hcl
provider_installation {
  # 内部 Provider 从本地镜像获取
  filesystem_mirror {
    path    = "/usr/share/terraform/providers"
    include = ["example.com/*/*"]
  }

  # 其他 Provider 直接从 Registry 下载
  direct {
    exclude = ["example.com/*/*"]
  }
}
```

`include` 和 `exclude` 支持通配符模式，省略 `registry.terraform.io/` 前缀等价于加上它。两者同时设置时，`exclude` 优先。

### 文件系统镜像目录结构

`filesystem_mirror` 目录支持两种布局：

**Packed 布局**（zip 文件）：

```
/usr/share/terraform/providers/
└── registry.terraform.io/
    └── hashicorp/
        └── aws/
            └── terraform-provider-aws_5.0.0_linux_amd64.zip
```

**Unpacked 布局**（解压后的目录）：

```
/usr/share/terraform/providers/
└── registry.terraform.io/
    └── hashicorp/
        └── aws/
            └── 5.0.0/
                └── linux_amd64/
                    └── terraform-provider-aws_v5.0.0_x5
```

使用 Unpacked 布局时，Terraform 会尝试创建符号链接而非复制，节省磁盘空间。

### 隐式本地镜像目录

即使没有配置 `provider_installation` 块，Terraform 也会自动检查以下目录作为隐式镜像：

- **Linux**: `~/.terraform.d/plugins`、`~/.local/share/terraform/plugins`
- **macOS**: `~/.terraform.d/plugins`、`~/Library/Application Support/io.terraform/plugins`
- **Windows**: `%APPDATA%/terraform.d/plugins`

如果当前工作目录存在 `terraform.d/plugins`，也会被自动识别。

### dev_overrides（Provider 开发者专用）

在开发 Provider 时，可以使用 `dev_overrides` 跳过版本验证和校验和检查，直接使用本地编译的插件：

```hcl
provider_installation {
  dev_overrides {
    "hashicorp/null" = "/home/developer/tmp/terraform-null"
  }

  # 其他 Provider 仍从 Registry 下载
  direct {}
}
```

::: warning
`dev_overrides` 仅用于 Provider 开发调试，不要在生产环境中使用。建议通过 `TF_CLI_CONFIG_FILE` 环境变量指向一个临时 `.tfrc` 文件，仅在开发会话中生效。
:::

## 配置项速查表

| 配置项 | 类型 | 说明 |
|--------|------|------|
| `plugin_cache_dir` | `string` | 插件缓存目录路径 |
| `disable_checkpoint` | `bool` | 完全禁用 Checkpoint 服务 |
| `disable_checkpoint_signature` | `bool` | 禁用匿名 ID 但保留版本检查 |
| `provider_installation` | block | 自定义 Provider 安装方式 |

::: tip 环境变量替代
大多数常用配置都有对应的环境变量，适合在 CI/CD 中使用：

| 配置项 | 环境变量 |
|--------|---------|
| `plugin_cache_dir` | `TF_PLUGIN_CACHE_DIR` |
| `disable_checkpoint` | `CHECKPOINT_DISABLE=1` |
| 配置文件路径 | `TF_CLI_CONFIG_FILE` |
:::

---

## 动手实验

<KillercodaEmbed src="https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-cli-config-file" />
