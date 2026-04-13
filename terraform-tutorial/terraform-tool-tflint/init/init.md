# tflint 实战

通过本节实验，你将体验 tflint 如何对 Terraform 代码进行静态分析，发现潜在问题并强制执行编码规范。

## 实验场景

工作目录中有一个故意包含多种问题的 Terraform 项目：

- 使用了废弃的插值语法 `"${var.x}"`
- 存在未使用的 variable 声明
- variable 缺少 description
- variable 缺少 type 声明
- output 缺少 description
- 命名不符合 snake_case 规范

你将使用 tflint 逐步发现并修复这些问题。

## 学习内容

| 内容 | 说明 |
|------|------|
| 基础检查 | 使用 tflint 扫描代码并理解输出 |
| 配置文件 | 编写 .tflint.hcl 启用规则插件 |
| 规则管理 | 启用/禁用特定规则，修复代码问题 |
| AWS 插件 | 引入云平台插件，体验 aws_resource_missing_tags、aws_s3_bucket_name、aws_provider_missing_default_tags 等扩展规则 |

点击右侧箭头开始实验。
