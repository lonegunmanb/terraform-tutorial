# terraform output 实战练习（Azure 版）

通过本节两个步骤，你将在真实的 Azure（[miniblue](https://miniblue.io/) 本地模拟器）环境中掌握 `terraform output` 的完整用法。

## 实验环境

miniblue 已启动（HTTP 4566 / HTTPS 4567）；自签名证书已写入 `/root/.miniblue/cert.pem` 并通过 `SSL_CERT_FILE` 环境变量被 Terraform 信任。同时已安装 `azlocal` CLI（类似 `awslocal`，走 HTTP 端口 4566，无需证书），用于在课程中校验 Azure 资源。Terraform 已完成 `init` 与 `apply`，创建了 1 个 Resource Group + 2 个 DNS Zone + 1 个 Virtual Network；配置中声明了多种类型的 output（string、list、map、sensitive）。

## 与 AWS 版的区别

本课程是 [terraform output（LocalStack 版）](https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-cli-output) 的 Azure 对照版本：所有 `terraform output` 子命令、参数、行为都完全一致，只是 provider 从 `aws` 换成 `azurerm`，模拟器从 LocalStack 换成了 miniblue，资源由 S3 桶 / DynamoDB 表换成了 Resource Group / DNS Zone / Virtual Network。

## 学习内容

| 步骤 | 内容 |
|------|------|
| 步骤 1 | 查看 output：全部列出、按名查询、sensitive 行为 |
| 步骤 2 | 自动化用法：-json、-raw 与脚本集成 |

点击右侧箭头开始第一步。
