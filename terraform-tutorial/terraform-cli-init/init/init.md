# terraform init 实战练习

本节通过三个动手步骤，带你彻底掌握 `terraform init` 命令的核心用法。

## 本节涵盖内容

| 步骤 | 练习内容 |
|------|---------|
| 步骤 1 | 初次初始化工作目录，探索 `.terraform/` 和 `.terraform.lock.hcl` |
| 步骤 2 | Provider 锁文件管理：`-upgrade` 与 `-lockfile=readonly` |
| 步骤 3 | Backend 切换与状态迁移：`-migrate-state` 和 `-reconfigure` |

## 实验环境

- **Terraform**：已预装
- **LocalStack**：本地 AWS 模拟环境（S3 服务），用于步骤 3 的 Backend 迁移演示
- **awslocal**：AWS CLI 的 LocalStack 封装，自动路由到本地端点

点击右侧箭头开始第一个练习。
