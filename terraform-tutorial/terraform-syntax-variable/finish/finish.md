# 🎉 实验完成！

你已经掌握了 Terraform 输入变量的核心知识，并用它们驱动创建了真实的 EC2 实例：

## 核心概念回顾

- **variable 块** — 定义输入变量，通过 `var.<NAME>` 引用
- **type** — 类型约束，限制变量接受的值的类型
- **default** — 默认值，未赋值时使用
- **description** — 描述，面向调用者的 API 文档
- **validation** — 自定义校验，用 `condition` + `error_message` 验证输入
- **sensitive** — 隐藏敏感值，防止在命令行输出中泄露
- **ephemeral** — 临时变量，不写入状态文件和计划文件
- **nullable** — 控制变量是否接受 `null` 值
- **赋值方式** — `-var`、`.tfvars`、`TF_VAR_` 环境变量、交互式输入
- **优先级** — 环境变量 < tfvars < auto.tfvars < 命令行参数
- **terraform test** — 用 `apply` 命令验证真实资源创建，用 `expect_failures` 测试 validation 拦截

## 下一步

返回教程主页，继续学习下一个章节。
