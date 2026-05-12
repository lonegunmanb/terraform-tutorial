# Terraform 基础：管理 Azure Virtual Network

欢迎来到 Terraform 基础实验的 Azure 版本！

在这个实验中，你将通过 [miniblue](https://miniblue.io/)（Azure 本地模拟器）学习如何使用 Terraform 完整地管理 Azure 资源的生命周期：

1. **创建** 一个 Resource Group 和 Virtual Network，并用 `azlocal` 命令验证
2. **验证幂等性** —— 重复执行 `terraform apply`，确认不会产生额外变更
3. **修改配置** —— 更改 VNet 的 `address_space`，观察 Terraform 如何就地更新
4. **销毁资源** —— 用 `terraform destroy` 清理所有资源

> 💡 本实验使用 miniblue 在本地模拟 Azure 环境，无需真实的 Azure 订阅和费用。
>
> 我们使用 `azlocal` 命令来校验资源（类似 LocalStack 的 `awslocal`），它走 HTTP 4566，无需证书。

> 📚 这是 [Terraform 基础（AWS / LocalStack 版）](https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-basics) 的 Azure 对照版本：所有命令、流程完全一致，只是 provider 从 `aws` 换成了 `azurerm`，资源从 EC2 实例换成了 Resource Group + Virtual Network。
