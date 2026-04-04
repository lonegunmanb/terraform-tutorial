# Terraform 重载文件

在这个实验中，你将通过两个步骤学习 Terraform 重载文件（Override Files）的核心用法。

重载文件允许你在不修改原始配置的情况下，用单独的文件覆盖已有对象的部分配置。你将通过以下步骤掌握重载文件的关键知识点：

1. **重载文件基础** — 基于一个完整的 VPC + NAT Gateway 基础设施配置，体验参数覆盖、嵌套块替换、lifecycle 合并、locals 合并等核心行为
2. **小测验** — 独立编写重载文件，用 terraform test 验证你的理解

> 💡 第一步使用 terraform validate 和 terraform console 来分析重载行为，无需部署真实资源。第二步使用 LocalStack 模拟 AWS 服务运行自动化测试。
