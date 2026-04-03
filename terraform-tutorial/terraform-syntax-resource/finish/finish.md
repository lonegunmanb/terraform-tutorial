# 🎉 实验完成！

你已经掌握了 Terraform 资源（resource）的核心知识：

## 核心概念回顾

- **resource 块** — `resource "类型" "名称" { ... }` 声明基础设施对象
- **属性引用** — `<类型>.<名称>.<属性>` 引用资源的输出属性
- **隐式依赖** — Terraform 通过表达式引用自动推导依赖顺序
- **depends_on** — 显式声明无法自动推导的依赖关系
- **count** — 创建多个相似资源，用数字索引访问
- **for_each** — 为集合中每个元素创建资源，用键访问，比 count 更稳定
- **lifecycle** — prevent_destroy 防删除、ignore_changes 忽略外部变更、create_before_destroy 先建后删
- **dynamic 块** — 根据变量动态生成重复的嵌套块
- **provisioner** — 创建/销毁时执行额外操作，应作为最后手段

## 下一步

返回教程主页，继续学习下一个章节。
