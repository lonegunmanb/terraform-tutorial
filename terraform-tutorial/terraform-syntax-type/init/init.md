# Terraform 类型系统

在这个实验中，你将学习 Terraform 的类型系统。

Terraform 中的每一个值都有类型，类型决定了值可以在哪里使用以及可以对它应用哪些操作。你将通过四个步骤掌握类型系统：

1. **原始类型** — `string`、`number`、`bool` 以及隐式类型转换
2. **集合类型** — `list`、`map`、`set`
3. **结构化类型** — `object`、`tuple`、`optional` 修饰符
4. **练习与测试** — 动手编写代码，用 `terraform test` 验证你的答案

> 💡 这个实验不需要云服务或 LocalStack，仅使用 Terraform 本地功能来练习类型系统。
