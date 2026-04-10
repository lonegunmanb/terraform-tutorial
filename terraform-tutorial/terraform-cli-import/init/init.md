# terraform import 实战练习

通过本节两个步骤，你将在真实的 AWS（LocalStack）环境中掌握 `terraform import` 的完整工作流。

## 实验环境

LocalStack 已启动，Terraform 已完成初始化。环境中预先通过 AWS CLI 创建了若干 S3 桶（**不是 Terraform 创建的**），你将把这些"已有基础设施"导入到 Terraform 管理中。

## 学习内容

| 步骤 | 内容 |
|------|------|
| 步骤 1 | terraform import 命令：手动导入单个资源、补全配置 |
| 步骤 2 | 导入到 for_each 资源 |

关于 `import` 块的声明式导入方式，请参考[代码重构](/refactor_module)章节。

点击右侧箭头开始第一步。
