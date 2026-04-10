---
order: 99
title: providers
group: Terraform CLI
group_order: 9
---

# terraform providers

`terraform providers` 命令族用于查看和管理配置所依赖的 provider 信息。包含一个主命令和三个子命令。

## terraform providers

显示当前配置的 provider 依赖树——每个 provider 的来源和版本约束，以及它是从哪个模块引入的：

```bash
terraform providers
```

输出示例：

```
Providers required by configuration:
.
├── provider[registry.terraform.io/hashicorp/aws] ~> 5.0
└── provider[registry.terraform.io/hashicorp/random] ~> 3.0
```

这在排查 "某个 provider 是从哪个模块引入的" 时非常有用。

## terraform providers schema

以 JSON 格式输出当前配置中所有 provider 的完整 schema（provider 配置、resource、data source 的所有属性定义）：

```bash
terraform providers schema -json
```

`-json` 是必选参数。输出是一个包含 `provider_schemas` 的 JSON 对象，每个 provider 下列出其：

- **provider**：provider 配置块的 schema
- **resource_schemas**：每种 resource 的属性定义
- **data_source_schemas**：每种 data source 的属性定义
- **functions**：provider 提供的函数签名

每个属性包含 `type`、`description`、`required`、`optional`、`computed`、`sensitive` 等字段。

典型用法：

```bash
# 查看某个 resource 有哪些属性
terraform providers schema -json | python3 -c "
import sys, json
schemas = json.load(sys.stdin)
aws = schemas['provider_schemas']['registry.terraform.io/hashicorp/aws']
bucket = aws['resource_schemas']['aws_s3_bucket']
for name, attr in bucket['block']['attributes'].items():
    req = 'required' if attr.get('required') else 'optional' if attr.get('optional') else 'computed'
    print(f'  {name}: {req}')
"
```

这在开发自动化工具、代码生成器或文档生成器时非常有价值。

## terraform providers lock

更新依赖锁文件（`.terraform.lock.hcl`），但不安装 provider。常规情况下，`terraform init` 会自动维护锁文件，但以下场景需要手动使用 `providers lock`：

### 跨平台支持

团队在不同平台（Windows、macOS、Linux）上运行 Terraform 时，需要为所有目标平台预填充 checksum：

```bash
terraform providers lock \
  -platform=linux_amd64 \
  -platform=darwin_amd64 \
  -platform=windows_amd64
```

### 使用镜像源

使用文件系统镜像或网络镜像时，`init` 无法获取来自官方 registry 的签名校验和。用 `providers lock` 可以从官方源记录校验和：

```bash
# 从本地文件系统镜像锁定
terraform providers lock \
  -fs-mirror=/usr/local/terraform/providers \
  -platform=linux_amd64

# 从网络镜像锁定
terraform providers lock \
  -net-mirror=https://mirror.example.com/providers/ \
  -platform=linux_amd64
```

### 锁定特定 provider

只更新指定 provider 的锁条目，不影响其他 provider：

```bash
terraform providers lock registry.terraform.io/hashicorp/aws
```

## terraform providers mirror

将当前配置需要的所有 provider 下载到本地目录，用于构建离线安装镜像：

```bash
terraform providers mirror /path/to/mirror
```

下载的文件按 registry 镜像的标准目录结构组织，可直接用作 `filesystem_mirror` 或上传为 `network_mirror`。

### 为多平台构建镜像

```bash
terraform providers mirror \
  -platform=linux_amd64 \
  -platform=darwin_amd64 \
  /path/to/mirror
```

可以多次运行，新平台的包会合并到已有目录中。

### 典型场景

| 场景 | 做法 |
|------|------|
| 气隙环境（无互联网） | 在有网络的机器上 `providers mirror`，将目录拷贝到隔离环境 |
| CI 缓存加速 | 在 CI 中预先 mirror 到共享缓存目录 |
| 团队统一版本 | mirror + lock 确保所有人使用相同版本和校验和 |

## 子命令汇总

| 命令 | 用途 | 是否修改文件 |
|------|------|------------|
| `terraform providers` | 查看 provider 依赖树 | 否 |
| `terraform providers schema -json` | 输出 provider schema | 否 |
| `terraform providers lock` | 更新 `.terraform.lock.hcl` | 是（锁文件） |
| `terraform providers mirror <dir>` | 下载 provider 到本地镜像目录 | 是（镜像目录） |

<KillercodaEmbed src="https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-cli-providers" />
