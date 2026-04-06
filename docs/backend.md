---
order: 4
title: Backend 配置
---

# Backend 配置

在[状态管理](./state)一章中，我们了解了 Terraform 为什么需要状态文件。默认情况下，Terraform 将状态文件存储在本地磁盘上——但在团队协作场景下，这远远不够。

**Backend**（后端）定义了 Terraform 在哪里以及如何存储状态数据。通过配置不同的后端，你可以将状态文件存储在远程共享存储中，实现团队协作、状态锁定和安全管理。

## 为什么需要远程后端？

本地后端（默认行为）有几个明显的局限性：

- **无法团队协作** — 状态文件存储在个人电脑上，团队成员无法共享
- **没有状态锁定** — 多人同时执行 `terraform apply` 时可能产生冲突，互相覆盖状态
- **缺乏安全保障** — 状态文件以明文形式存储在本地，包含敏感信息（密码、密钥等）
- **没有版本历史** — 状态文件被覆盖后无法恢复

远程后端解决了所有这些问题：状态文件集中存储在共享存储中，支持并发锁定，可以通过访问控制限制读写权限，还可以结合对象存储的版本控制功能保留历史版本。

## backend 块

后端通过 `terraform` 块中的 `backend` 子块来配置。`backend` 关键字后的标签指定后端类型：

```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
}
```

### 配置限制

backend 块有几个重要的限制：

1. **每个配置只能有一个 backend 块** — 不能同时使用多个后端
2. **不能使用变量和表达式** — backend 块中的所有值必须是字面量，不能引用 `var.xxx`、`local.xxx` 或数据源属性
3. **不能在外部引用 backend 块中的值** — backend 配置是封闭的

```hcl
# ❌ 不合法！
variable "bucket" {
  default = "my-state-bucket"
}

terraform {
  backend "s3" {
    bucket = var.bucket  # Error: Variables not allowed
  }
}
```

这些限制存在的原因是：backend 配置在 Terraform 处理所有其他配置之前就需要被解析——在变量、数据源等尚未就绪的阶段。

## 默认本地后端

当没有显式配置 backend 块时，Terraform 使用 `local` 后端——状态文件 `terraform.tfstate` 直接存储在当前工作目录中：

```hcl
# 以下两种写法等价：

# 不写 backend 块（默认使用 local）
terraform {
  required_version = ">= 1.0"
}

# 显式配置 local 后端
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
```

本地后端适合个人学习和实验，但在生产环境中应使用远程后端。

## 常用后端类型

Terraform 内置了多种后端类型。以下是最常用的几种：

| 后端类型 | 存储位置 | 状态锁定 | 适用场景 |
|---------|---------|---------|---------|
| `local` | 本地磁盘 | 仅文件锁 | 个人开发、学习 |
| `s3` | AWS S3 | 支持（S3 lockfile 或 DynamoDB） | AWS 项目 |
| `consul` | Consul KV | 支持 | 多云、HashiCorp 生态 |
| `gcs` | Google Cloud Storage | 支持 | GCP 项目 |
| `azurerm` | Azure Blob Storage | 支持 | Azure 项目 |
| `http` | 任意 HTTP 端点 | 可选 | 自定义存储 |

### S3 后端

S3 后端将状态文件存储在 AWS S3 存储桶中，是最广泛使用的远程后端之一：

```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
}
```

核心参数：

- **`bucket`**（必填）— S3 存储桶名称
- **`key`**（必填）— 状态文件在桶中的路径
- **`region`**（必填）— S3 存储桶所在区域

可选但推荐的参数：

- **`encrypt`** — 启用服务端加密
- **`use_lockfile`** — 启用基于 S3 的状态锁定（推荐）

::: tip 生产环境推荐
在生产中使用 S3 后端时，强烈建议：
1. 为 S3 存储桶启用**版本控制**，以便在出错时恢复状态
2. 设置 `encrypt = true` 启用服务端加密
3. 设置 `use_lockfile = true` 启用状态锁定
:::

### Consul 后端

Consul 后端将状态存储在 [HashiCorp Consul](https://www.consul.io/) 的 KV（键值）存储中。Consul 原生支持状态锁定：

```hcl
terraform {
  backend "consul" {
    address = "consul.example.com"
    scheme  = "https"
    path    = "terraform/myapp/state"
  }
}
```

核心参数：

- **`path`**（必填）— Consul KV 存储中的路径
- **`address`**（可选）— Consul agent 地址，默认 `127.0.0.1:8500`
- **`scheme`**（可选）— HTTP 或 HTTPS，默认 `http`
- **`access_token`**（可选）— Consul ACL token，推荐通过 `CONSUL_HTTP_TOKEN` 环境变量传递

Consul 后端的一个优势是它不依赖于任何云平台——适合多云或混合云场景。

## 初始化后端

每当修改了 backend 配置，都必须重新运行 `terraform init` 来初始化后端：

```bash
terraform init
```

`terraform init` 会：
1. 验证 backend 配置是否合法
2. 创建 `.terraform/` 目录，存储后端配置和 Provider 缓存
3. 如果检测到 backend 配置变更，提示是否迁移状态

::: warning
`.terraform/` 目录包含后端配置（可能含有凭据），**不要将其提交到版本控制系统**。
:::

## 状态迁移

当你修改 backend 配置时（例如从本地后端切换到 S3），`terraform init` 会检测到变更，并提示你是否要将现有状态迁移到新后端：

```
Initializing the backend...
Backend configuration changed!

Terraform has detected that the configuration specified for the backend
has changed. Terraform will now check for existing state in the backends.

Do you want to migrate all workspaces to "s3"?

  Enter a value: yes
```

输入 `yes` 后，Terraform 会：
1. 从旧后端读取当前状态
2. 将状态写入新后端
3. 更新本地 `.terraform/terraform.tfstate` 中的后端配置

::: tip 迁移前备份
在迁移状态之前，强烈建议手动备份当前状态文件：
```bash
cp terraform.tfstate terraform.tfstate.backup
```
:::

如果想跳过交互式确认，可以使用 `-migrate-state` 参数：

```bash
terraform init -migrate-state
```

## 部分配置 (Partial Configuration)

由于 backend 块不支持变量，敏感信息（如访问密钥）不应硬编码在配置文件中。Terraform 提供了**部分配置**机制，允许将部分参数推迟到 `init` 阶段再提供。

**配置文件中只声明后端类型，不填参数：**

```hcl
terraform {
  backend "s3" {}
}
```

**通过配置文件提供剩余参数：**

```hcl
# backend.hcl
bucket = "my-terraform-state"
key    = "prod/terraform.tfstate"
region = "us-east-1"
```

```bash
terraform init -backend-config=backend.hcl
```

推荐的命名约定：`*.backendname.tfbackend`（例如 `config.s3.tfbackend`）。这有助于编辑器识别文件类型并提供更好的编辑体验。

**通过命令行参数提供：**

```bash
terraform init \
  -backend-config="bucket=my-terraform-state" \
  -backend-config="key=prod/terraform.tfstate" \
  -backend-config="region=us-east-1"
```

**通过环境变量提供：**

部分后端支持通过环境变量配置。例如 S3 后端支持 `AWS_ACCESS_KEY_ID`、`AWS_SECRET_ACCESS_KEY` 等标准 AWS 环境变量；Consul 后端支持 `CONSUL_HTTP_TOKEN` 等。

::: info 部分配置的优先级
当多种方式同时提供参数时，命令行参数覆盖配置文件中的值，配置文件覆盖主配置中的值。
:::

## 移除后端配置

要从远程后端切换回本地后端，只需删除 `backend` 块并重新运行 `terraform init`。Terraform 会提示你是否要将状态迁移回本地：

```
Terraform has detected you're unconfiguring your previously set "s3" backend.

Do you want to migrate all workspaces to "local"?

  Enter a value: yes
```

## 🧪 动手实验

在下面的实验环境中，你将亲手体验后端配置和状态迁移：

1. **本地后端** — 使用默认的本地后端创建资源，探索状态文件
2. **S3 后端** — 配置 S3 后端（使用 LocalStack 模拟），将状态迁移到远程存储，体验状态锁定
3. **部分配置** — 将后端参数从代码中分离，通过配置文件和命令行参数提供

<KillercodaEmbed src="https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-backend" />
