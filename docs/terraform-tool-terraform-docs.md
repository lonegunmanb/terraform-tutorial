---
order: 20
title: terraform-docs
group: 周边工具
group_order: 17
---

# terraform-docs：模块文档自动生成

[terraform-docs](https://github.com/terraform-docs/terraform-docs) 是一个从 Terraform 模块自动生成文档的工具。它解析模块中的 `variable`、`output`、`resource`、`provider` 等定义，以结构化格式输出，彻底消除手工维护文档的负担。

## 解决什么问题

Terraform 模块的用户需要了解模块的输入变量、输出值、资源依赖和版本约束。随着模块复杂度增长，手工维护 README 既容易遗漏又容易与代码脱节。`terraform-docs` 直接从 `.tf` 文件中提取元数据，确保文档始终与代码一致。

## 安装

```bash
# macOS (Homebrew)
brew install terraform-docs

# Linux（下载预编译二进制）
curl -Lo ./terraform-docs.tar.gz \
  https://github.com/terraform-docs/terraform-docs/releases/download/v0.22.0/terraform-docs-v0.22.0-$(uname)-amd64.tar.gz
tar -xzf terraform-docs.tar.gz
chmod +x terraform-docs
mv terraform-docs /usr/local/bin/

# Go install
go install github.com/terraform-docs/terraform-docs@v0.22.0

# 验证
terraform-docs version
```

## 基本用法

### 生成 Markdown 文档

```bash
# 输出到终端
terraform-docs markdown .

# 输出为表格格式
terraform-docs markdown table .

# 输出为文档格式（非表格）
terraform-docs markdown document .
```

### 其他输出格式

```bash
# JSON（适合程序解析）
terraform-docs json .

# YAML
terraform-docs yaml .

# 简洁的彩色文本
terraform-docs pretty .

# 生成 tfvars 模板（含所有变量默认值）
terraform-docs tfvars hcl .
```

### 注入到 README

最常用的模式：将生成的文档注入到 README.md 的指定位置。在 README.md 中添加标记：

```markdown
<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
```

然后运行：

```bash
terraform-docs markdown table --output-file README.md --output-mode inject .
```

`terraform-docs` 会用生成的内容替换两个标记之间的部分，保留标记之外的自定义内容。

## 配置文件

通过 `.terraform-docs.yml` 进行丰富的定制。配置文件按以下顺序查找：

1. 模块根目录
2. 模块根目录的 `.config/` 子目录
3. 当前目录
4. `$HOME/.tfdocs.d/`

### 基础配置示例

```yaml
formatter: markdown table

output:
  file: README.md
  mode: inject
  template: |-
    <!-- BEGIN_TF_DOCS -->
    &#123;&#123; .Content &#125;&#125;
    <!-- END_TF_DOCS -->

sort:
  enabled: true
  by: name

settings:
  anchor: true
  default: true
  required: true
  sensitive: true
  type: true
```

有了配置文件后，只需运行 `terraform-docs .` 即可，不需要命令行参数。

### 递归生成子模块文档

```yaml
recursive:
  enabled: true
  path: modules
  include-main: true
```

### 隐藏/显示特定区块

```yaml
sections:
  hide:
    - providers
    - modules
  show: []
```

## 内容模板

`content` 字段允许完全自定义文档结构和顺序：

```yaml
content: |-
  &#123;&#123; .Header &#125;&#125;

  ## 使用方法

  ```hcl
  &#123;&#123; include "examples/basic/main.tf" &#125;&#125;
  ```

  &#123;&#123; .Requirements &#125;&#125;

  &#123;&#123; .Inputs &#125;&#125;

  &#123;&#123; .Outputs &#125;&#125;

  &#123;&#123; .Resources &#125;&#125;
```

可用的模板变量：

| 变量 | 说明 |
|------|------|
| `&#123;&#123; .Header &#125;&#125;` | 从 `header-from` 文件提取的描述 |
| `&#123;&#123; .Footer &#125;&#125;` | 从 `footer-from` 文件提取的内容 |
| `&#123;&#123; .Inputs &#125;&#125;` | 输入变量表 |
| `&#123;&#123; .Outputs &#125;&#125;` | 输出值表 |
| `&#123;&#123; .Providers &#125;&#125;` | Provider 列表 |
| `&#123;&#123; .Requirements &#125;&#125;` | 版本约束 |
| `&#123;&#123; .Resources &#125;&#125;` | 资源列表 |
| `&#123;&#123; .Modules &#125;&#125;` | 子模块引用 |
| `&#123;&#123; include "path" &#125;&#125;` | 包含外部文件内容 |

## CI/CD 集成

### pre-commit hook

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/terraform-docs/terraform-docs
    rev: "v0.22.0"
    hooks:
      - id: terraform-docs-go
        args: ["markdown", "table", "--output-file", "README.md", "."]
```

### GitHub Actions

```yaml
- name: Render terraform docs
  uses: terraform-docs/gh-actions@main
  with:
    working-dir: .
    output-file: README.md
    output-method: inject
    git-push: "true"
```

### CI 文档检查脚本

在 CI 中检查文档是否是最新的：

```bash
#!/bin/bash
cp README.md README-before.md
terraform-docs .
if ! diff -q README.md README-before.md >/dev/null 2>&1; then
  echo "README.md 不是最新的！请运行 terraform-docs 后重新提交"
  rm README-before.md
  exit 1
fi
rm README-before.md
```

## 与其他工具的关系

| 工具 | 职责 |
|------|------|
| `terraform-docs` | 从代码生成文档（README） |
| `terraform fmt` | 代码缩进和对齐 |
| `avmfix` | 属性排序、块排列、文件归位 |
| `hcledit` | 命令式属性读写 |

---

## 动手实验

<KillercodaEmbed src="https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-tool-terraform-docs" />
