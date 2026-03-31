# Terraform 基础：管理 EC2 实例

欢迎来到 Terraform 的第一个实验！

在这个实验中，你将学习如何使用 Terraform 完整地管理一台 EC2 虚拟机的生命周期：

1. **创建**一台 EC2 实例，并用 `awslocal` 命令验证
2. **验证幂等性**——重复执行 `terraform apply`，确认不会产生额外变更
3. **修改配置**——更改实例类型，观察 Terraform 如何处理变更
4. **销毁资源**——用 `terraform destroy` 清理所有资源

> 💡 本实验使用 LocalStack 模拟 AWS 环境，无需真实的 AWS 账号和费用。
>
> 我们使用 `awslocal` 命令来代替 `aws --endpoint-url=http://localhost:4566`，它是 LocalStack 提供的 AWS CLI 封装工具，自动指向本地 LocalStack 端点。
