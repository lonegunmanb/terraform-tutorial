# terraform state 实战练习（Azure / miniblue 版）

通过本节三个步骤，你将在真实的 Azure（[miniblue](https://miniblue.io/) 本地模拟器）环境中掌握 terraform state 子命令。

## 实验环境

miniblue 已启动（HTTP 4566 / HTTPS 4567）；自签名证书已写入 /root/.miniblue/cert.pem 并通过 SSL_CERT_FILE 环境变量被 Terraform 信任。同时已安装 azlocal CLI（类似 awslocal，走 HTTP 4566，无需证书）。

Terraform 已完成初始化并 apply 了以下资源：

| 资源 | 名称 |
|------|------|
| Resource Group | state-demo-rg |
| Virtual Network | state-demo-vnet |
| Subnet | state-demo-app |
| Subnet | state-demo-logs |
| Subnet | state-demo-data |

## 与 AWS 版的区别

本课程是 [terraform state（LocalStack 版）](https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-cli-state) 的 Azure 对照版本：所有 state 子命令、参数、工作流都完全一致，只是 provider 从 aws 换成 azurerm，模拟器从 LocalStack 换成了 miniblue，资源类型从 S3 桶 + DynamoDB 表换成了 Resource Group + Virtual Network + Subnet（3 个 subnet 对应原 AWS 版的 3 个 S3 桶）。

## 学习内容

| 步骤 | 内容 |
|------|------|
| 步骤 1 | state list / state show / state pull：读取状态信息 |
| 步骤 2 | state mv：在状态中移动/重命名资源 |
| 步骤 3 | state rm：从状态中移除资源 |

点击右侧箭头开始第一步。
