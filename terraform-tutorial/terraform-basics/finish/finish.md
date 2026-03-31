# 🎉 实验完成！

你已经成功完成了 EC2 实例的完整生命周期管理：

| 操作 | 命令 | 说明 |
|------|------|------|
| 创建 | `terraform init` + `terraform apply` | 初始化并创建 EC2 实例 |
| 验证 | `awslocal ec2 describe-instances` | 用 AWS CLI 确认资源状态 |
| 修改 | 编辑 `.tf` → `terraform apply` | 更改实例类型（就地更新） |
| 销毁 | `terraform destroy` | 清理所有资源 |

## 关键概念回顾

- **幂等性**：重复执行 `apply`，如果状态已经一致，Terraform 不会做任何变更
- **Plan → Apply**：先预览再执行，安全地管理基础设施变更
- **声明式管理**：你只需声明期望状态，Terraform 负责计算和执行差异

## 下一步

返回教程主页，继续学习 **状态管理** 章节，了解 Terraform 是如何追踪和管理你创建的资源的。
