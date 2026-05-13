# 恭喜完成 terraform output 实战练习（Azure 版）！

## 知识总结

| 功能 | 命令 | 核心场景 |
|------|------|---------|
| 查看所有 output | terraform output | 快速检视基础设施的关键信息 |
| 查看单个 output | terraform output NAME | 查询特定值（包括 sensitive） |
| 原始字符串输出 | terraform output -raw NAME | Shell 脚本赋值（不带引号） |
| JSON 格式输出 | terraform output -json | 自动化提取、CI/CD 传递值 |
| 无颜色输出 | terraform output -no-color | 日志采集 |

## Azure 版要点回顾

- 本课程用 [miniblue](https://miniblue.io/) 在本地完整模拟 Azure REST API，无需真实订阅
- azurerm provider 通过 metadata_host = "localhost:4567" 指向 miniblue 的 HTTPS 端点
- 资源由 Resource Group + DNS Zone + Virtual Network 组成，配合 azlocal CLI 可验证 output 中的资源名是否真的存在于 miniblue
- 所有 terraform output 子命令、参数、行为与 AWS / LocalStack 版完全一致——这正是 Terraform 多云抽象的价值所在

## 关键要点

- terraform output 只显示**根模块**的 output，子模块的 output 需在根模块显式暴露
- 列出所有 output 时，sensitive 值显示为 &lt;sensitive&gt;；按名称查询时显示实际值
- -json 和 -raw 输出中，sensitive 值均以明文显示
- -raw 只支持 string、number、bool；复合类型必须用 -json
- terraform output 是只读命令，不会修改状态或资源
