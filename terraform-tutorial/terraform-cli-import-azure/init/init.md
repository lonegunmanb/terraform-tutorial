# terraform import 实战练习（Azure 版）

通过本节两个步骤，你将在真实的 Azure（[miniblue](https://miniblue.io/) 本地模拟器）环境中掌握 `terraform import` 的完整工作流。

## 实验环境

miniblue 已启动（HTTP 4566 / HTTPS 4567）；自签名证书已写入 `/root/.miniblue/cert.pem` 并通过 `SSL_CERT_FILE` 环境变量被 Terraform 信任。同时已安装 `azlocal` CLI（类似 `awslocal`，走 HTTP 端口 4566，无需证书），用于校验 Azure 资源。azurerm provider 已通过 `terraform init` 下载完毕。

环境中预先通过 miniblue 的 ARM API 直接创建了若干 Resource Group（**不是 Terraform 创建的**），你将把这些"已有基础设施"导入到 Terraform 管理中。

## 与 AWS 版的区别

本课程是 [terraform import（LocalStack 版）](https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-cli-import) 的 Azure 对照版本：所有 import 子命令、参数、工作流都完全一致，只是 provider 从 `aws` 换成 `azurerm`，模拟器从 LocalStack 换成了 miniblue，被导入的资源从 S3 桶换成了 Resource Group。

| 步骤 | 内容 |
|------|------|
| 步骤 1 | terraform import 命令：手动导入单个资源、补全配置 |
| 步骤 2 | 导入到 for_each 资源 |

关于 `import` 块的声明式导入方式，请参考[代码重构](/refactor_module)章节。

点击右侧箭头开始第一步。
