# Terraform 输入变量

在这个实验中，你将学习 Terraform 的输入变量（variable）。

输入变量是 Terraform 配置的参数化机制——把一组代码想象成一个函数，输入变量就是函数的入参。通过变量，你可以让同一份代码在不同场景下创建不同的基础设施。

你将通过五个步骤掌握输入变量：

1. **变量基础** — 定义变量、类型约束、默认值、描述、引用方式
2. **断言校验** — 用 `validation` 对输入值进行自定义校验
3. **敏感值与临时变量** — `sensitive`、`ephemeral`、`nullable`
4. **赋值方式与优先级** — `-var`、`.tfvars`、`.auto.tfvars`、`TF_VAR_` 环境变量、交互式输入
5. **练习：用变量创建 EC2** — 综合运用所学知识，用变量驱动创建真实 EC2 实例，用 `terraform test` 验证

> 💡 前四步仅使用 Terraform 本地功能练习输入变量。第五步（练习题）会使用 LocalStack 模拟 AWS，创建真实的 EC2 实例。
