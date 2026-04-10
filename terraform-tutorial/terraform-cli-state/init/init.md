# terraform state 实战练习

通过本节三个步骤，你将在真实的 AWS（LocalStack）环境中掌握 terraform state 子命令。

## 实验环境

LocalStack 已启动，Terraform 已完成初始化并 apply 了以下资源：

| 资源 | 名称 |
|------|------|
| S3 桶 | state-demo-app |
| S3 桶 | state-demo-logs |
| S3 桶 | state-demo-data |
| DynamoDB 表 | state-demo-locks |

## 学习内容

| 步骤 | 内容 |
|------|------|
| 步骤 1 | state list / state show / state pull：读取状态信息 |
| 步骤 2 | state mv：在状态中移动/重命名资源 |
| 步骤 3 | state rm：从状态中移除资源 |

点击右侧箭头开始第一步。
