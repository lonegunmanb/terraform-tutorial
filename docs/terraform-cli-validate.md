---
order: 95
title: validate
group: Terraform CLI
group_order: 9
---

# terraform validate

`terraform validate` 检查配置文件是否**语法正确、内部一致**，但不访问任何远端服务（不读取 state，不调用 provider API）。它适合作为编辑器保存后检查、CI pre-commit 门禁和模块单元测试的验证步骤。

## 用法

```bash
terraform validate [options]
```

validate 需要一个已初始化的工作目录（插件和模块已下载）。如果只是想验证语法而不连接 backend，可以用：

```bash
terraform init -backend=false
terraform validate
```

## 验证范围

`terraform validate` 检查的内容包括：

| 检查项 | 示例 |
|--------|------|
| HCL 语法 | 花括号未闭合、引号不匹配 |
| 属性名正确性 | 资源类型不存在的属性（如 `buckeet` 拼错） |
| 值类型匹配 | 将 `string` 赋给 `number` 类型的变量 |
| 必填属性缺失 | 资源块中缺少必填参数 |
| 引用合法性 | 引用了不存在的变量或资源 |
| 块结构正确性 | provider 块中使用了不支持的嵌套块 |

`terraform validate` **不检查**的内容：

- 远端资源是否存在
- 变量值是否满足业务约束（如 CIDR 格式）
- provider API 是否可达
- state 文件是否一致

这些运行时问题需要通过 `terraform plan` 或 `terraform apply` 发现。

## 选项

### -json

以机器可读的 JSON 格式输出验证结果，适合 CI 系统和编辑器集成：

```bash
terraform validate -json
```

成功时输出：

```json
{
  "valid": true,
  "error_count": 0,
  "warning_count": 0,
  "diagnostics": []
}
```

失败时 `diagnostics` 数组包含每个错误/警告的详细信息，包括严重级别（`error`/`warning`）、摘要、详情和源码位置：

```json
{
  "valid": false,
  "error_count": 1,
  "warning_count": 0,
  "diagnostics": [
    {
      "severity": "error",
      "summary": "Unsupported argument",
      "detail": "An argument named \"buckeet\" is not expected here. Did you mean \"bucket\"?",
      "range": { "filename": "main.tf", "start": { "line": 5, "column": 3 } }
    }
  ]
}
```

### -no-color

禁用终端颜色输出。

## validate 与 plan 的区别

| | `terraform validate` | `terraform plan` |
|---|---|---|
| 需要通过 provider 调用远端 API | 否（只需插件已安装） | 是（需要连通远端服务） |
| 需要 state | 否 | 是 |
| 检查语法和类型 | 是 | 是（隐含 validate） |
| 检查运行时约束 | 否 | 是 |
| 检查远端状态差异 | 否 | 是 |
| 适合场景 | 编辑器保存、CI pre-commit | 变更前的完整预览 |

`terraform plan` 在执行前会隐含运行一次 validate。因此，如果 plan 成功了，validate 一定也是通过的；但 validate 通过不代表 plan 一定成功。

## 在 CI 中的典型用法

```bash
# 1. 初始化（不连接 backend，仅下载插件）
terraform init -backend=false

# 2. 格式检查
terraform fmt -check -recursive

# 3. 语法验证
terraform validate

# 4. 完整规划（需要 backend 和 credentials）
terraform plan -input=false -no-color
```

validate 放在 fmt 之后、plan 之前——快速拦截语法错误，避免消耗远端 API 调用。

<KillercodaEmbed src="https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-cli-validate" />
