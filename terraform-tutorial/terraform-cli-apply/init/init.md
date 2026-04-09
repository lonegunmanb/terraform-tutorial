# terraform apply 实战练习

通过本节四个步骤，你将在真实的 AWS（LocalStack）环境中掌握 `terraform apply` 的完整工作流。

## 实验环境

LocalStack 已启动，Terraform 已完成初始化（`terraform init` 已运行，providers 已下载），但尚未创建任何资源。你将在第一步亲手执行首次 apply，亲眼看到资源从无到有的过程。

## 学习内容

| 步骤 | 内容 |
|------|------|
| 步骤 1 | 首次 apply：创建资源、理解确认流程与 -auto-approve |
| 步骤 2 | 两步工作流：plan 保存计划 + apply 执行计划文件 |
| 步骤 3 | 定向 apply（-target）与强制重建（-replace） |
| 步骤 4 | 只更新 state（-refresh-only）与机器可读输出（-json） |

点击右侧箭头开始第一步。
