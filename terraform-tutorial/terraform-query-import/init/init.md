# terraform query 与批量导入实战

通过本节实验，你将掌握如何将大量已有资源批量导入 Terraform 管理。

## 实验环境

MiniStack 已启动，并且**已预先创建了若干 S3 桶和 DynamoDB 表**——这些资源模拟的是手动创建或由其他工具管理的已有基础设施。你的任务是将它们纳入 Terraform 管理。本实验使用 AWS Provider v6.x 和 Terraform v1.12+，支持 terraform query 功能。

## 预创建的资源

| 类型 | 名称 |
|------|------|
| S3 桶 | app-prod-data, app-prod-logs, app-prod-assets |
| S3 桶 | app-staging-data, app-staging-logs |
| DynamoDB 表 | app-prod-sessions, app-prod-cache |

## 学习内容

| 步骤 | 内容 |
|------|------|
| 步骤 1 | 使用 import + for_each 批量导入 S3 桶 |
| 步骤 2 | 编写 .tfquery.hcl 查询配置与 terraform query 命令 |
| 步骤 3 | 练习：自己完成 DynamoDB 表的批量导入 |

点击右侧箭头开始实验。
