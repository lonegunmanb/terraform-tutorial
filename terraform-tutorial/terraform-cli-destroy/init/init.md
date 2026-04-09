# terraform destroy 实战练习

通过本节三个步骤，你将在真实的 AWS（LocalStack）环境中掌握 `terraform destroy` 的完整用法。

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
| 步骤 1 | 预览销毁与交互确认：terraform destroy 基本流程 |
| 步骤 2 | 定向销毁（-target）与变量传入 |
| 步骤 3 | 两步销毁工作流与 destroy 后重建 |
| 步骤 4 | 依赖顺序销毁：VPC 网络资源实战 |

点击右侧箭头开始第一步。
