# Terraform Checks

在这个实验中，你将学习 Terraform 的 check 块——一种在资源生命周期之外验证基础设施状态的机制。

check 块是 Terraform v1.5.0 引入的功能，与 precondition / postcondition 不同，check 的断言失败**只产生警告，不会阻止操作**。

你将通过以下两个步骤掌握 check 块的用法：

1. **check 块演示** — 观察 check 块、assert 断言和有限作用域数据源的行为
2. **小测验** — 补全缺失的 check 块，用 terraform test 验证答案

> 💡 本实验使用 LocalStack 模拟 AWS 服务，所有操作都在本地完成，无需真实 AWS 账号。
