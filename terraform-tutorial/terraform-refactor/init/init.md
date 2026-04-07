# Terraform 代码重构

在这个实验中，你将学习如何使用 Terraform 的三种重构配置块——import、removed、moved——安全地重组代码结构，而不销毁任何真实基础设施。

你将通过以下四个步骤掌握重构技能：

1. **import** — 将已有的 S3 桶纳入 Terraform 管理
2. **removed** — 从 Terraform 管理中移除资源，但保留实际桶
3. **moved（重命名）** — 给资源起一个更好的名字，不销毁不重建
4. **moved（提取模块）** — 将根模块中的资源提取到子模块中

> 💡 本实验使用 LocalStack 模拟 AWS 服务，所有操作都在本地完成，无需真实 AWS 账号。你将使用 awslocal 命令来观察实际的 S3 桶状态。
