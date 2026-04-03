# 🎉 实验完成！

你已经掌握了 Terraform 输出值的核心知识：

## 核心概念回顾

- **output 块** — 定义 Terraform 代码的返回值，`value` 为必填参数
- **description** — 面向模块调用者的 API 文档
- **sensitive** — 隐藏命令行输出中的敏感值，但状态文件中仍是明文
- **precondition** — 在计算 value 之前校验条件，防止不合法的值写入状态文件
- **depends_on** — 显式声明输出值对特定资源的依赖（极少使用）
- **ephemeral** — 临时输出值，不记录到状态文件和计划文件（v1.10+，仅限子模块）

## 常用命令

- `terraform output` — 查看所有输出值
- `terraform output <NAME>` — 查看特定输出值
- `terraform output -json` — 以 JSON 格式输出（可查看 sensitive 值）
- `terraform output -raw <NAME>` — 原始格式输出（不含引号）

## 下一步

返回教程主页，继续学习下一个章节。
