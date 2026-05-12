# terraform destroy 实战练习（Azure 版）

通过本节四个步骤，你将在真实的 Azure（[miniblue](https://miniblue.io/) 本地模拟器）环境中掌握 `terraform destroy` 的完整用法。

## 实验环境

miniblue 已启动（HTTP 4566 / HTTPS 4567）；自签名证书已写入 `/root/.miniblue/cert.pem` 并通过 `SSL_CERT_FILE` 环境变量被 Terraform 信任。同时已安装 `azlocal` CLI（走 HTTP 端口 4566，无需证书），用于在课程中校验 Azure 资源。

已为你通过 `terraform apply` 预先创建好四个 Azure 资源：

| 资源类型 | 资源名称 |
|----------|---------|
| Resource Group | myapp-dev-rg-lab |
| Virtual Network | myapp-dev-vnet-lab |
| Subnet | myapp-dev-app-lab |
| Subnet | myapp-dev-logs-lab |

## 与 AWS 版的区别

本课程是 [terraform destroy（LocalStack 版）](https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-cli-destroy) 的 Azure 对照版本：所有 destroy 子命令、参数、工作流都完全一致，只是 provider 从 `aws` 换成 `azurerm`，模拟器从 LocalStack 换成了 miniblue。

## 学习内容

| 步骤 | 内容 |
|------|------|
| 步骤 1 | 预览销毁与交互确认：terraform destroy 基本流程 |
| 步骤 2 | 定向销毁（-target）与变量传入 |
| 步骤 3 | 两步销毁工作流与 destroy 后重建 |
| 步骤 4 | 依赖顺序销毁：time_sleep 与 depends_on 实战 |

点击右侧箭头开始第一步。
