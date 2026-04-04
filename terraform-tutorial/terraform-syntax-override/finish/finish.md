# 🎉 实验完成！

你已经掌握了 Terraform 重载文件（Override Files）的核心知识：

## 核心概念回顾

- **重载文件命名** — `override.tf` 或 `*_override.tf` 后缀的文件被特殊处理
- **加载顺序** — 先加载普通文件，再按文件名字典序逐个加载重载文件
- **参数覆盖** — 重载块中的参数覆盖源块中的同名参数，未提及的参数保持不变
- **嵌套块替换** — 普通嵌套块被整体替换，不会逐参数合并
- **lifecycle 特殊处理** — lifecycle 块按参数合并，而非整体替换
- **locals 合并** — 按命名值逐条合并，不论所在的 locals 块
- **variable 合并** — type 和 default 的修改需要保持类型一致性
- **terraform 块合并** — required_providers 逐 Provider 合并，required_version 完全覆盖

## 下一步

返回教程主页，继续学习下一个章节。
