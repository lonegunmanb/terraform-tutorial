# Terraform 状态管理

Terraform 的状态文件（`terraform.tfstate`）是它的"记忆"——记录了哪些资源是由 Terraform 创建和管理的。

在这个实验中，环境已经预先执行了 `terraform apply`，创建了以下资源：

- 2 个 S3 存储桶（`my-app-data-bucket`、`my-app-logs-bucket`）
- 1 个 DynamoDB 表（`terraform-locks`）

你将通过三个步骤深入理解状态文件：

1. **探索状态文件** — 查看状态命令，对比代码与状态文件的信息差异
2. **漂移检测** — 在 Terraform 外部修改资源，观察 Terraform 如何发现并修复漂移
3. **删除资源** — 从代码中删除资源定义，理解状态文件为什么不可或缺

> 💡 Terraform 只管理它状态文件中记录的资源。理解这个边界是掌握 Terraform 的关键。
