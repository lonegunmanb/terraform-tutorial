# Terraform Provider 配置

Terraform 需要通过 **Provider** 插件来管理基础设施。在使用任何资源之前，你必须告诉 Terraform 去哪里找到对应的 Provider——这就是 `required_providers` 的作用。

在这个实验中，你将亲手体验一个常见的错误场景：

1. **Provider 的声明** — 观察缺少 `required_providers` 时 `terraform init` 的失败，理解声明的必要性
2. **练习与测验** — 回答关于 Provider 源地址和本地名称的问题

> 💡 当你从网上复制 Terraform 代码时，如果只复制了 `resource` 和 `provider` 块，却忘了 `terraform` 块中的 `required_providers` 声明，代码很可能无法工作——尤其是使用非 HashiCorp 官方命名空间的 Provider 时。
