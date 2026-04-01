# Terraform 配置语法

在这个实验中，你将学习 HCL（HashiCorp Configuration Language）的基础语法元素。

HCL 是 Terraform 的配置语言，它融合了声明式语言的简洁和命令式语言的表达力。你将通过三个步骤掌握基础语法：

1. **块与参数** — HCL 的基本结构单元：块类型、标签、参数赋值
2. **注释与字符串** — 注释风格、字符串插值、Heredoc 多行字符串
3. **练习与测试** — 动手编写代码，用 `terraform test` 验证你的答案

> 💡 这个实验不需要云服务或 LocalStack，仅使用 Terraform 本地功能（locals 和 outputs）来练习语法。
