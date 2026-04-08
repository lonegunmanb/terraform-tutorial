# terraform plan 实战练习

通过本节四个步骤，你将在真实的 AWS（LocalStack）环境中掌握 `terraform plan` 的全部核心能力。

## 实验环境

已为你准备好三个 AWS 资源（通过 LocalStack 模拟）：

| 资源类型 | 资源名称 |
|----------|---------|
| S3 Bucket | myapp-dev-app-lab |
| S3 Bucket | myapp-dev-logs-lab |
| DynamoDB Table | myapp-dev-sessions |

## 学习内容

| 步骤 | 内容 |
|------|------|
| 步骤 1 | 理解计划输出：符号、结构、无变更与有变更 |
| 步骤 2 | 规划模式：-destroy 和 -refresh-only |
| 步骤 3 | 保存计划（-out）、资源定向（-target）、强制重建（-replace） |
| 步骤 4 | 变量注入（-var / -var-file）与退出码（-detailed-exitcode） |

点击右侧箭头开始第一步。
