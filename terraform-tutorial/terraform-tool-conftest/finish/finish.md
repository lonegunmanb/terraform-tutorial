# 恭喜完成！

你已经体验了 Conftest 的核心功能：

## Rego 策略编写

- **deny 规则**：违规时阻止部署（非零退出码）
- **warn 规则**：建议性检查，不阻止部署
- **input 数据**：Terraform Plan JSON 中的 resource_changes、configuration 等字段

## 策略管理

- **命名空间**：用 Rego package 组织策略，支持选择性运行
- **例外机制**：通过 exception 规则跳过特定检查
- **远程策略**：用 --update 从 Git 等远程源拉取策略

## 输出与集成

- **多种输出格式**：table、json、junit 等
- **--no-fail 模式**：适合逐步引入策略的过渡阶段

## 推荐工作流

```
terraform plan -out=tfplan.binary       # 1. 生成计划
terraform show -json tfplan.binary > tfplan.json  # 2. 导出 JSON
conftest test -o table tfplan.json      # 3. 策略检查
terraform apply tfplan.binary           # 4. 通过后部署
```

## Conftest vs Checkov

两者可以互补使用：

| 场景 | 推荐工具 |
|------|----------|
| 通用安全最佳实践（加密、公开访问等） | checkov（内置规则，开箱即用） |
| 组织特有策略（命名规范、标签要求等） | conftest（Rego 自定义策略） |
| 合规标准对照（CIS、PCI-DSS） | checkov |
| 基于 Plan 的精确检查 | conftest |

## 延伸阅读

- [Conftest GitHub](https://github.com/open-policy-agent/conftest)
- [OPA Rego 语言参考](https://www.openpolicyagent.org/docs/latest/policy-language/)
- [Conftest 详解（Terraform 模块之道）](https://lonegunmanb.github.io/dao-of-terraform-modules/%E5%B7%A5%E5%85%B7%E9%93%BE/conftest.html)
- [AWS Policy as Code 示例](https://github.com/aws-samples/aws-infra-policy-as-code-with-terraform)
- [Rego 101 中文教程](https://xie.infoq.cn/article/c053620f2f0165de7846d83b8)
