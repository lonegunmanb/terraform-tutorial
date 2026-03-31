# Terraform 状态管理

在这个实验中，环境已经预先执行了 `terraform apply`，创建了以下资源：

- 2 个 S3 存储桶（`my-app-data-bucket`、`my-app-logs-bucket`）
- 1 个 DynamoDB 表（`terraform-locks`）

你的任务是学习如何查看、操作和理解 Terraform 的状态文件。

> 💡 状态文件是 Terraform 将代码与真实资源关联起来的关键。理解它是进阶的必经之路。
