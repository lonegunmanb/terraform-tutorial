# 🎉 实验完成！

你已经理解了 Terraform Provider 配置的关键概念：

## 核心概念回顾

- **Provider** — Terraform 的插件，提供资源类型和数据源，与外部平台交互
- **源地址** — Provider 的全球唯一标识，格式为 hostname/namespace/type
- **本地名称** — 在当前模块中引用 Provider 的别名，对应资源类型名的第一个单词
- **required_providers** — 在 terraform 块中声明 Provider 的来源和版本，是正确使用 Provider 的前提
- **依赖锁定文件** — .terraform.lock.hcl 确保团队使用相同的 Provider 版本

## 关键教训

复制 Terraform 代码时，不要只复制 resource 和 provider 块——**务必确保 terraform 块中的 required_providers 声明完整**，否则：
- 非 hashicorp 命名空间的 Provider 会直接初始化失败
- hashicorp 命名空间的 Provider 虽能工作，但缺少版本约束可能导致兼容性问题

## 下一步

返回教程主页，继续学习 **Terraform 模块** 章节。
