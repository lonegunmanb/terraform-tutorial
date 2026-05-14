# terraform show 实战练习（Azure 版）

通过本节三个步骤，你将在真实的 Azure（[miniblue](https://miniblue.io/) 本地模拟器）环境中掌握 `terraform show` 的完整用法。

## 实验环境

miniblue 已启动（HTTP 4566 / HTTPS 4567）；自签名证书已写入 `/root/.miniblue/cert.pem` 并通过系统 CA 信任链 + `SSL_CERT_FILE` 环境变量被 Terraform 信任。同时已安装 `azlocal` CLI（类似 `awslocal`，走 HTTP 端口 4566，无需证书），用于在课程中校验 Azure 资源。Terraform 已完成初始化并通过 `terraform apply -auto-approve` 创建了资源（1 个 Resource Group + 1 个 Virtual Network + 2 个 Subnet），你可以直接使用 `terraform show` 查看状态。

## 与 AWS 版的区别

本课程是 [terraform show（LocalStack 版）](https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-cli-show) 的 Azure 对照版本：所有 `terraform show` 子命令、参数、解析脚本都完全一致，只是 provider 从 `aws` 换成 `azurerm`，模拟器从 LocalStack 换成了 miniblue。这正体现了 `terraform show` 作为通用只读命令的多云一致性。

## 学习内容

| 步骤 | 内容 |
|------|------|
| 步骤 1 | 查看当前状态：人类可读输出与资源属性检索 |
| 步骤 2 | 查看计划文件：审查已保存的执行计划 |
| 步骤 3 | JSON 机器可读输出：状态与计划的 JSON 格式解析 |

点击右侧箭头开始第一步。
