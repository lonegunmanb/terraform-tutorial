# terraform validate 实战练习（Azure 版）

通过本节三个步骤，你将在 Azure（[miniblue](https://miniblue.io/) 本地模拟器）配置上掌握 `terraform validate` 的验证范围、错误定位和 CI 集成能力。

## 实验环境

已为你准备好一份包含 azurerm Resource Group 的 Terraform 配置，azurerm provider 已下载（`terraform init` 已完成）。miniblue 已启动并通过 `SSL_CERT_FILE` 信任了自签名证书，但本课程的所有命令都不需要连接 miniblue —— `terraform validate` 是离线的语法 / 引用检查，不会调用任何 provider API。

## 与 AWS 版的区别

本课程是 [terraform validate（LocalStack 版）](https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-cli-validate) 的 Azure 对照版本：所有 validate 子命令、参数、错误类别、CI 集成方式都完全一致，只是 provider 从 `aws` 换成 `azurerm`，演示资源从 `aws_s3_bucket` 换成了 `azurerm_resource_group` / `azurerm_virtual_network`。

## 学习内容

| 步骤 | 内容 |
|------|------|
| 步骤 1 | validate 通过与失败：属性拼写、类型不匹配、引用不存在 |
| 步骤 2 | 常见错误类型：必填缺失、引用不存在的资源、与 plan 的区别 |
| 步骤 3 | -json 机器可读输出与 CI 集成脚本 |

点击右侧箭头开始第一步。
