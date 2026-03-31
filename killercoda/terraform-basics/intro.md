# Terraform 基础：Init / Plan / Apply

欢迎来到 Terraform 的第一个实验！

在这个实验中，你将学习 Terraform 最核心的三步工作流：

1. **`terraform init`** — 初始化项目，下载所需的 Provider 插件
2. **`terraform plan`** — 预览将要执行的变更（干跑模式）
3. **`terraform apply`** — 将变更应用到真实环境

我们已经为你准备好了一个 `main.tf` 配置文件，它定义了一个 S3 存储桶。
你的任务是使用 Terraform 三步流将它创建出来。

> 💡 本实验使用 LocalStack 模拟 AWS 环境，无需真实的 AWS 账号和费用。
