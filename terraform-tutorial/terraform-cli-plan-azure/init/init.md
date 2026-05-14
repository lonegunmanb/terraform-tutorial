# terraform plan 实战练习（Azure 版）

通过本节四个步骤，你将在真实的 Azure（[miniblue](https://miniblue.io/) 本地模拟器）环境中掌握 `terraform plan` 的全部核心能力。

## 实验环境

miniblue 已启动（HTTP 4566 / HTTPS 4567）；自签名证书已写入 `/root/.miniblue/cert.pem` 并通过 `SSL_CERT_FILE` 环境变量被 Terraform 信任。同时已安装 `azlocal` CLI（类似 `awslocal`，走 HTTP 端口 4566，无需证书），用于在课程中校验 Azure 资源。

已为你预先 `terraform apply` 创建了四个 Azure 资源（通过 miniblue 模拟）：

| 资源类型 | 资源名称 |
|----------|---------|
| Resource Group | myapp-dev-rg-lab |
| DNS Zone | myapp-dev-app-lab.local |
| DNS Zone | myapp-dev-logs-lab.local |
| Virtual Network | myapp-dev-vnet-lab |

## 与 AWS 版的区别

本课程是 [terraform plan（LocalStack 版）](https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-cli-plan) 的 Azure 对照版本：所有 plan 子命令、参数、工作流都完全一致，只是 provider 从 `aws` 换成 `azurerm`，模拟器从 LocalStack 换成了 miniblue，资源类型从 S3 Bucket / DynamoDB Table 换成了 Resource Group / DNS Zone / Virtual Network。

## 学习内容

| 步骤 | 内容 |
|------|------|
| 步骤 1 | 理解计划输出：符号、结构、无变更与有变更 |
| 步骤 2 | 规划模式：-destroy 和 -refresh-only |
| 步骤 3 | 保存计划（-out）、资源定向（-target）、强制重建（-replace） |
| 步骤 4 | 变量注入（-var / -var-file）与退出码（-detailed-exitcode） |

点击右侧箭头开始第一步。
