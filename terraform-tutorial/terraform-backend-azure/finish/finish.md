# 实验完成！

你已经在 Azure（miniblue）环境中掌握了 Terraform 后端配置的核心概念和操作。

## 核心概念回顾

- **后端 (Backend)** 决定了 Terraform 状态文件的存储位置
- **本地后端** 是默认行为，状态存储在当前目录的 terraform.tfstate 文件中
- **azurerm 后端** 将状态以 blob 形式存储在 Azure Storage Account 的 Container 中，支持团队协作
- **blob lease 状态锁** 直接作用在状态 blob 上，无需独立锁表
- **状态迁移** 通过修改 backend 配置并运行 terraform init 完成
- **部分配置** 允许将敏感信息从代码中分离，通过配置文件、命令行参数或 ARM_* 环境变量提供

## 命令速查

| 命令 | 作用 |
|------|------|
| terraform init | 初始化后端，检测变更并提示迁移 |
| terraform init -migrate-state | 跳过交互确认，直接迁移 |
| terraform init -backend-config=FILE | 使用部分配置文件初始化 |
| terraform init -backend-config="KEY=VALUE" | 通过命令行键值对提供后端参数 |

## 与 AWS / S3 后端的对照

| 主题 | S3 后端 | azurerm 后端 |
|------|---------|-------------|
| 状态对象 | S3 Bucket 中的 object | Storage Account/Container 中的 blob |
| 锁机制 | DynamoDB 表 | blob lease（无需独立锁表） |
| 凭据环境变量 | AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY | ARM_CLIENT_ID / ARM_CLIENT_SECRET / ARM_TENANT_ID |
| 端点定制 | endpoints {} 块 | metadata_host |

## 下一步

返回教程主页，继续学习 **Terraform 语法** 章节。
