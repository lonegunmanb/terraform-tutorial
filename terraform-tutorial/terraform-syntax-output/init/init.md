# Terraform 输出值

在这个实验中，你将学习 Terraform 输出值（output）的各种用法。

输出值是 Terraform 代码的"返回值"——就像函数的返回值一样，它让你把基础设施创建后产生的信息导出，供外部使用或传递给其他模块。

你将通过三个步骤掌握所有关键知识点：

1. **output 基础与 description** — 声明输出值、使用 description 和 terraform output 命令
2. **sensitive 与 precondition** — 隐藏敏感输出、为输出值添加前置校验
3. **练习与测试** — 动手编写代码，用 `terraform test` 验证你的答案

> 💡 这个实验不需要云服务或 LocalStack，仅使用 Terraform 本地功能（locals 和 outputs）来练习。
