# 实验完成！

你已经掌握了 Terraform 后端配置的核心概念和操作。

## 核心概念回顾

- **后端 (Backend)** 决定了 Terraform 状态文件的存储位置
- **本地后端** 是默认行为，状态存储在当前目录的 terraform.tfstate 文件中
- **远程后端**（如 S3）将状态存储在共享存储中，支持团队协作和状态锁定
- **状态锁定** 通过 DynamoDB 防止多人同时修改状态
- **状态迁移** 通过修改 backend 配置并运行 terraform init 完成
- **部分配置** 允许将敏感信息从代码中分离，通过配置文件或命令行参数提供

## 命令速查

| 命令 | 作用 |
|------|------|
| terraform init | 初始化后端，检测变更并提示迁移 |
| terraform init -migrate-state | 跳过交互确认，直接迁移 |
| terraform init -backend-config=FILE | 使用部分配置文件初始化 |
| terraform init -backend-config="KEY=VALUE" | 通过命令行键值对提供后端参数 |

## 下一步

返回教程主页，继续学习 **Terraform 语法** 章节。

## 下一步

返回教程主页，继续学习 **Terraform 语法** 章节。
