# 🎉 实验完成！

你已经掌握了 Terraform 数据源（data）的核心知识：

## 核心概念回顾

- **data 块** — `data "类型" "名称" { ... }` 声明只读数据查询
- **引用语法** — `data.<类型>.<名称>.<属性>`，以 `data.` 开头
- **data vs resource** — data 只读查询，resource 增删改管理
- **查询环境信息** — `aws_caller_identity`、`aws_region` 等不需要参数
- **查询已有资源** — `aws_s3_bucket`、`aws_sqs_queue` 等需要标识参数
- **读取时机** — 参数已知 → plan 阶段读取；参数依赖未创建资源 → apply 阶段读取
- **terraform test** — 通过 `.tftest.hcl` 文件验证配置的断言

## 下一步

返回教程主页，继续学习下一个章节。
