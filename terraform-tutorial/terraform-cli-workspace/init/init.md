# terraform workspace 实战练习

通过本节四个步骤，你将在真实的 AWS（LocalStack）环境中掌握 terraform workspace 的完整工作流，并理解 CLI workspace 与 HCP Terraform workspace 的本质区别。

## 实验环境

LocalStack 已启动，Terraform 已完成初始化（terraform init 已运行，providers 已下载），但尚未创建任何资源。你将使用 workspace 管理同一套配置的多个环境副本。

## 学习内容

| 步骤 | 内容 |
|------|------|
| 步骤 1 | 默认 workspace 与基础命令（show / list / new） |
| 步骤 2 | 在不同 workspace 中部署独立资源 |
| 步骤 3 | workspace 切换与状态隔离原理 |
| 步骤 4 | 清理 workspace：销毁资源与删除 workspace |

## 重要概念

本实验使用的是 Terraform CLI workspace——它是同一工作目录下的多份 state 实例。这与 HCP Terraform（原 Terraform Cloud）的 workspace 是完全不同的概念。HCP Terraform 的 workspace 各有独立的配置、变量、凭证和权限，相当于独立的工作目录；CLI workspace 仅隔离 state，所有 workspace 共享同一份配置和 backend 凭证。

点击右侧箭头开始第一步。
