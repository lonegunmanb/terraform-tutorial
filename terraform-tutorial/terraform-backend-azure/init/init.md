# Terraform Backend 配置（Azure / miniblue 版）

在这个实验中，你将学习 Terraform 后端（Backend）的配置和使用。后端决定了 Terraform 在哪里存储状态文件。本课程是 [Terraform Backend 配置（LocalStack 版）](https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-backend) 的 Azure 对照版本：所有 backend 概念、迁移流程、部分配置完全一致，只是 provider 从 `aws` 换成 `azurerm`，状态存储从 S3 + DynamoDB 换成了 Azure Storage Account + Blob Container（状态锁定由 blob lease 提供）。

实验环境已预装：

- Terraform CLI
- miniblue（Azure 本地模拟器，HTTP 4566 / HTTPS 4567）
- azlocal CLI（类似 awslocal，HTTP 4566，无需证书）
- 自签名证书已通过 `SSL_CERT_FILE` 信任

你将通过三个步骤掌握后端配置：

1. **默认本地后端** — 使用本地后端创建资源（包括一个 Storage Account 和 Container），探索状态文件
2. **azurerm 后端** — 将状态迁移到上一步创建的 Blob Container 中，体验远程后端与基于 blob 租约（lease）的状态锁定
3. **部分配置** — 将后端参数从代码中分离，适配 CI/CD 与多环境场景

点击右侧箭头开始第一步。
