# Terraform CLI 基础命令实战（Azure 版）

欢迎来到 Terraform CLI 基础命令实验的 Azure 对照版本！

本实验聚焦于那些不需要直接操作云资源、但同样重要的 Terraform CLI 命令：

1. **version 与 -chdir** —— 查看版本、安装自动补全、不切目录直接指定路径
2. **terraform fmt** —— 格式化代码，特意准备了一个缩进混乱的文件供你练习
3. **terraform console** —— 交互式计算 HCL 表达式，调试变量和内置函数
4. **terraform get 与 graph** —— 下载模块、生成资源依赖图
5. **terraform force-unlock** —— 解除崩溃进程留下的孤儿状态锁

## 实验环境

工作目录已预置一份 `azurerm` provider 的配置（两个 `azurerm_resource_group`，含 `depends_on` 依赖），并通过 [miniblue](https://miniblue.io/) 在本地完整模拟了 Azure 控制平面。`terraform init` 已在 background 里跑完，azurerm provider 已下载，但本课程**不会**真正 apply 这两个 Resource Group——所有命令都只在本地 HCL/state 上执行，无需等待云资源。

## 与 AWS 版的区别

本课程是 [Terraform CLI 基础（LocalStack 版）](https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-cli-basics) 的 Azure 对照版本：所有 CLI 子命令、参数与流程都完全一致，只是 provider 从 `null` / `aws` 换成 `azurerm`，`force-unlock` 演示从 S3 + DynamoDB 后端换成本地 backend + 长时 apply 模拟孤儿锁的方式（更贴近多人本地协作时 Ctrl+C / OOM kill 的真实场景）。

> 💡 Killercoda 终端是非登录交互 shell，`SSL_CERT_FILE` 已通过 `~/.bashrc` 自动导出。如果你在新开的子 shell 里发现 Terraform 报证书错误，运行 `source ~/.bashrc` 即可。

点击右侧箭头开始第一步。
