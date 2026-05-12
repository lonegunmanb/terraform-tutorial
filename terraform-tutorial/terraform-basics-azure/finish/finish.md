# 🎉 实验完成！

你已经成功在 Azure（miniblue）环境中完成了完整的资源生命周期管理：

| 操作 | 命令 | 说明 |
|------|------|------|
| 创建 | terraform init + terraform apply | 初始化并创建 Resource Group + VNet |
| 验证 | azlocal group list / azlocal network vnet list | 用 azlocal CLI 确认资源状态 |
| 修改 | 编辑 .tf → terraform apply | 更改 VNet 地址空间（就地更新） |
| 销毁 | terraform destroy | 清理所有资源 |

## 关键概念回顾

- **幂等性**：重复执行 apply，如果状态已经一致，Terraform 不会做任何变更
- **Plan → Apply**：先预览再执行，安全地管理基础设施变更
- **声明式管理**：你只需声明期望状态，Terraform 负责计算和执行差异
- **跨云一致性**：本实验与 AWS/LocalStack 版的命令、流程完全一致——证明 Terraform 工作流不依赖具体云厂商

## 下一步

返回教程主页，继续学习 **状态管理** 章节，了解 Terraform 是如何追踪和管理你创建的资源的。
