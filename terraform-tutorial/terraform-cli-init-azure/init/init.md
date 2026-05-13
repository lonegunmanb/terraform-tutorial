# terraform init 实战练习（Azure 版）

本节通过三个动手步骤，带你在真实的 Azure（[miniblue](https://miniblue.io/) 本地模拟器）环境中彻底掌握 `terraform init` 命令的核心用法。

## 本节涵盖内容

| 步骤 | 练习内容 |
|------|---------|
| 步骤 1 | 初次初始化工作目录，探索 `.terraform/` 和 `.terraform.lock.hcl` |
| 步骤 2 | Provider 锁文件管理：`-upgrade` 与 `-lockfile=readonly` |
| 步骤 3 | Backend 切换与状态迁移：`-migrate-state` 和 `-reconfigure` |

## 实验环境

- **Terraform**：已预装
- **miniblue**：Azure 本地模拟器（HTTP 4566 / HTTPS 4567），自签名证书已通过 `SSL_CERT_FILE` 信任
- **azlocal**：类似 `awslocal`，走 HTTP 4566 调用 ARM 控制面，无需证书
- **Storage Account**：步骤 3 用到的 `tfstate-rg` / `tfstateinit` / `tfstate` 已预先创建

## 与 AWS 版的区别

本课程是 [terraform init（AWS / LocalStack 版）](https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-cli-init) 的 Azure 对照版本：所有 init 子命令、参数、工作流都完全一致，只是 provider 从 `null`/`aws` 换成 `azurerm`，远端状态存储从 LocalStack 的 S3 桶换成了 miniblue 的 Azure Blob Container。

点击右侧箭头开始第一个练习。
