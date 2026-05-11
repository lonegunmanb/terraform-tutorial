# terraform apply 实战练习（Azure 版）

通过本节四个步骤，你将在真实的 Azure（[miniblue](https://miniblue.io/) 本地模拟器）环境中掌握 `terraform apply` 的完整工作流。

## 实验环境

miniblue 已启动（端口 4566 / 4567），自签名证书已写入 `/root/.miniblue/cert.pem` 并通过 `SSL_CERT_FILE` 环境变量被 Terraform 信任，azurerm provider 已通过 `terraform init` 下载完毕，但尚未创建任何 Azure 资源。你将在第一步亲手执行首次 apply，亲眼看到资源从无到有的过程。

## 与 AWS 版的区别

本课程是 [terraform apply（LocalStack 版）](https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-cli-apply) 的 Azure 对照版本：所有 apply 子命令、参数、工作流都完全一致，只是 provider 从 `aws` 换成 `azurerm`，模拟器从 LocalStack 换成了 miniblue（镜像锁定为 `moabukar/miniblue:0.7.0`）。配置中包含 1 个 Resource Group + 2 个 DNS Zone + 1 个 Virtual Network，用于体验定向 apply 与强制重建。

## 学习内容

| 步骤 | 内容 |
|------|------|
| 步骤 1 | 首次 apply：创建资源、理解确认流程与 -auto-approve |
| 步骤 2 | 两步工作流：plan 保存计划 + apply 执行计划文件 |
| 步骤 3 | 定向 apply（-target）与强制重建（-replace） |
| 步骤 4 | 只更新 state（-refresh-only）与机器可读输出（-json） |

点击右侧箭头开始第一步。
