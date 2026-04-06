# Terraform Backend 配置

在这个实验中，你将学习 Terraform 后端（Backend）的配置和使用。后端决定了 Terraform 在哪里存储状态文件。

实验环境已预装：
- Terraform CLI
- AWS CLI（awslocal，用于访问 LocalStack）
- LocalStack（模拟 AWS S3 和 DynamoDB）

你将通过三个步骤掌握后端配置：

1. **默认本地后端** — 使用本地后端创建资源（包括一个状态存储桶），探索状态文件
2. **S3 后端** — 将状态迁移到上一步创建的 S3 桶中，体验远程后端和状态锁定
3. **部分配置** — 将后端参数从代码中分离，适配 CI/CD 和多环境场景
