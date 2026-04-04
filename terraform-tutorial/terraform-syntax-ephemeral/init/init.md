# Terraform 临时资源 (ephemeral)

在这个实验中，你将通过对比实验理解 Terraform 临时资源（ephemeral）的核心特性——**不写入状态文件**。

临时资源是 Terraform v1.10 引入的新块类型，适合获取短期凭据、生成临时密码等场景。它拥有"打开—续约—关闭"的独特生命周期，确保敏感数据不会被持久化。

你将通过以下三个步骤掌握临时资源的关键知识点：

1. **ephemeral vs resource** — 用 `random_password` 对比两种方式在状态文件中的差异
2. **ephemeral + Secrets Manager** — 用临时资源生成密码并存入 AWS Secrets Manager，体会安全传递凭据的模式
3. **小测验** — 用 terraform test 检验你对临时资源的理解

> 💡 本实验使用 LocalStack 模拟 AWS 服务，所有操作都在本地完成，无需真实 AWS 账号。
