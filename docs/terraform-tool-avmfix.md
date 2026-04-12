---
order: 19
title: avmfix
group: 周边工具
group_order: 17
---

# avmfix：Terraform 模块代码规范化工具

[avmfix](https://github.com/lonegunmanb/avmfix) 是一个自动化的 Terraform 代码格式修复工具，最初为 [Azure Verified Modules (AVM)](https://aka.ms/avm) 规范设计，但其排序和规范化能力适用于任何 Terraform 模块项目。

`terraform fmt` 只处理缩进和对齐，而 `avmfix` 更进一步——它关注的是**块内属性的顺序**、**块间的排列**以及**文件组织结构**。

## 解决什么问题

当团队中多人协作开发 Terraform 模块时，代码风格很容易出现不一致：

- 同一个 `resource` 块中，有人把 `tags` 写在最前面，有人写在最后
- `variable` 块的 `type`、`default`、`description` 顺序不统一
- `output` 块没有按字母排序，查找困难
- `variable` 块散落在各个 `.tf` 文件中，而非集中在 `variables.tf`
- `moved` 块中 `from` 和 `to` 的顺序不一致

这些看似小问题，在代码审查和维护时会累积成实际负担。`avmfix` 通过自动化格式修复消除这类争论。

## 自动修复能力

| 修复项 | 说明 |
|--------|------|
| `resource`/`data` 块内排序 | 元参数（`count`、`for_each`、`provider`）在前，普通属性按 Schema 顺序，`lifecycle`/`depends_on` 在后 |
| `variable` 块内排序 | `type` → `default` → `description` → `nullable` → `sensitive` → `validation` |
| `output` 块排序 | 按名称字母顺序排列 |
| `locals` 块排序 | 按名称字母顺序排列 |
| `module` 块内排序 | `source` → `version` → `providers` → `for_each`/`count` → 必填变量（字母序）→ 可选变量（字母序）→ `depends_on` |
| `moved` 块排序 | `from` 在前，`to` 在后 |
| 文件归位 | 不在 `*variables*.tf` 中的 `variable` 块移至 `variables.tf`；不在 `*outputs*.tf` 中的 `output` 块移至 `outputs.tf` |
| 冗余声明清理 | 移除 `nullable = true`（默认值）和 `sensitive = false`（默认值） |

## 安装

```bash
# Go install（需要 Go 1.21+）
go install github.com/lonegunmanb/avmfix@latest

# 验证
avmfix -h
```

## 使用方法

```bash
# 修复指定模块目录
avmfix -folder /path/to/your/terraform/module

# 修复当前目录
avmfix -folder .
```

`avmfix` 会直接修改 `.tf` 文件（原地修改），建议在版本控制下运行，方便审查变更。

成功时输出：`DirectoryAutoFix completed successfully.`

## Provider Schema 支持

`avmfix` 通过动态获取 Provider 和 Module 的 Schema 来确定属性顺序，支持所有 Terraform CLI 兼容的 Provider。这意味着它不仅适用于 Azure，也能正确处理 AWS、GCP、阿里云等任何 Provider 的资源块排序。

## 与 terraform fmt 的对比

| 对比 | `terraform fmt` | `avmfix` |
|------|----------------|---------|
| 缩进/对齐 | ✅ | ❌（不处理，交给 `terraform fmt`） |
| 块内属性排序 | ❌ | ✅ |
| 块间排序（output/locals） | ❌ | ✅ 字母序 |
| 文件归位（variable→variables.tf） | ❌ | ✅ |
| 冗余声明清理 | ❌ | ✅ |
| module 块排序 | ❌ | ✅ |

推荐的使用顺序：先 `avmfix`，再 `terraform fmt`。

## 在 CI/CD 中使用

`avmfix` 非常适合集成到 CI 管道中作为格式检查。AVM 项目的做法是：在 pre-commit 或 CI 中运行 `avmfix`，然后检查是否有文件变动——如果有，说明代码未经过格式化，要求开发者重新提交。

```bash
#!/bin/bash
# CI 格式检查脚本
avmfix -folder .
if [ -n "$(git status -s)" ]; then
  echo "avmfix 检测到格式问题，请在本地运行 avmfix 后重新提交"
  git diff
  exit 1
fi
```

对于包含多个 examples 和子模块的项目：

```bash
#!/bin/bash
avmfix -folder "$(pwd)"

# 修复 examples 子目录
for d in $(find ./examples -maxdepth 1 -mindepth 1 -type d); do
  echo "===> Autofix in $d" && avmfix -folder "$d"
done

# 修复 modules 子目录
if [ -d modules ]; then
  for d in $(find ./modules -maxdepth 1 -mindepth 1 -type d); do
    echo "===> Autofix in $d" && avmfix -folder "$d"
  done
fi
```

## 与其他工具的关系

| 工具 | 职责 |
|------|------|
| `terraform fmt` | 缩进、对齐、空白格式化 |
| `avmfix` | 属性排序、块排列、文件归位、冗余清理 |
| `mapotf` | 声明式批量代码变换（ignore_changes、治理规则） |
| `hcledit` | 命令式单属性读写 |

---

## 动手实验

<KillercodaEmbed src="https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-tool-avmfix" />
