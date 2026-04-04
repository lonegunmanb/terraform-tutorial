# 🎉 实验完成！

你已经掌握了 Terraform 临时资源（ephemeral）的核心知识：

## 核心概念回顾

- **ephemeral 块** — `ephemeral "类型" "名称" { ... }` 声明临时资源，不写入状态文件
- **生命周期** — 打开→续约→关闭，与 resource 的增删改和 data 的只读查询完全不同
- **引用限制** — 只能在 local、provider、ephemeral output 等临时上下文中引用
- **与 sensitive 的区别** — sensitive 只隐藏输出，数据仍在状态文件中；ephemeral 彻底不持久化
- **write-only 属性** — 搭配 ephemeral 实现端到端的状态文件零敏感数据

## 下一步

返回教程主页，继续学习下一个章节。
