# terraform test 实战练习

通过本节四个步骤，你将在真实的 AWS（LocalStack）环境中掌握 Terraform 原生测试框架的完整用法。

## 实验环境

LocalStack 已启动，Terraform 已完成初始化（terraform init 已运行，providers 已下载），但尚未创建任何资源。你将通过 terraform test 命令来验证和测试配置。

## 学习内容

| 步骤 | 内容 |
|------|------|
| 步骤 1 | 第一个测试：plan 模式断言与变量覆盖 |
| 步骤 2 | 集成测试：apply 模式创建真实资源并验证 |
| 步骤 3 | 辅助模块、expect_failures 与 Mock Provider |
| 步骤 4 | 综合练习：自己编写测试 |

点击右侧箭头开始第一步。
