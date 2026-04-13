# 恭喜完成！

你已经体验了 tflint 的核心功能：

## Terraform 语言规则（内置插件）

- **废弃语法检测**：发现 "${var.x}" 等过时写法
- **未使用声明检测**：找出从未引用的 variable、data 等
- **命名约定检查**：强制 snake_case 命名规范
- **文档完整性**：确保 variable 和 output 有 description
- **类型声明检查**：确保 variable 声明了 type
- **规则自定义**：通过配置文件启用/禁用规则

## AWS 插件扩展规则

- **aws_resource_missing_tags**：强制所有资源包含指定标签（Team、Project 等）
- **aws_s3_bucket_name**：强制 S3 桶名称匹配组织前缀或正则规则
- **aws_provider_missing_default_tags**：强制在 Provider 级别配置默认标签

## 推荐工作流

```
tflint --init               # 1. 初始化插件
tflint                      # 2. 静态分析
terraform fmt                # 3. 格式化
terraform validate           # 4. 语义检查
terraform plan               # 5. 计划变更
```

## 延伸阅读

- [tflint GitHub](https://github.com/terraform-linters/tflint)
- [tflint 规则列表](https://github.com/terraform-linters/tflint-ruleset-terraform/blob/main/docs/rules/README.md)
- [tflint 详解（Terraform 模块之道）](https://lonegunmanb.github.io/dao-of-terraform-modules/%E5%B7%A5%E5%85%B7%E9%93%BE/tflint.html)
- [AWS 规则插件](https://github.com/terraform-linters/tflint-ruleset-aws)
- [Azure 规则插件](https://github.com/terraform-linters/tflint-ruleset-azurerm)
