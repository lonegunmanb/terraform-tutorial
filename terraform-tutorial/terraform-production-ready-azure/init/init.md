# 生产就绪：三层 Web 应用架构（Azure 版）

本实验以经典的 Azure 三层 Web 架构为蓝本，从一个"一锅炖"的单体配置出发，用 moved 块一步步重构为模块化的基础设施代码——全程不销毁、不重建任何资源。

## 架构概览

典型的三层 Web 架构包含以下层级：

```
┌──────────────────────────────────────────────────────────────┐
│  网络层：VNet · 公有/私有子网 · NSG                              │
├──────────────────────────────────────────────────────────────┤
│  Web 层：Load Balancer · Linux VM · NSG (LB/App/Data)          │
├──────────────────────────────────────────────────────────────┤
│  数据层：Cosmos DB 用户表                                       │
├──────────────────────────────────────────────────────────────┤
│  存储层：Storage Account 静态资源 · Storage Account 备份         │
├──────────────────────────────────────────────────────────────┤
│  安全层：Managed Identity · Role Assignment · Key Vault · App Configuration │
└──────────────────────────────────────────────────────────────┘
```

本实验在 miniblue 上模拟这套架构。miniblue 支持 VNet、Subnet、Load Balancer、NSG、VM 等网络与计算资源，以及 Storage Account、Cosmos DB、Key Vault、App Configuration、Managed Identity 等数据与安全服务。

## 我们要构建什么

一个跨两个可用区的 Web 应用基础设施，包含约 30 个资源：

- **网络层**：Resource Group + VNet + 4 个子网 + 4 个 NSG 关联
- **Web 层**：Public IP + Load Balancer + 后端池 + 探测器 + 规则 + Network Interface + Linux VM + 三组 NSG（LB / App / Data）
- **数据层**：Cosmos DB 帐户 + Cosmos DB 表
- **存储层**：Storage Account 静态资源 + Storage Account 备份 + 生命周期管理策略
- **安全层**：User Assigned Identity + Role Assignment × N + Key Vault + App Configuration

## 实验环境

- Terraform 1.14+
- AzureRM Provider 4.x
- Terragrunt 0.77+
- miniblue（Azure 资源模拟，含 VNet/VM/LB/Storage/CosmosDB/KeyVault 等）
- 工作目录：/root/workspace/（所有步骤在同一目录操作）
