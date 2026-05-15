# 恭喜完成 terraform state 实战练习（Azure / miniblue 版）！

## 知识总结

| 子命令 | 用途 | 是否修改状态 |
|--------|------|:---:|
| state list | 列出状态中所有资源 | 否 |
| state show | 查看单个资源的详细属性 | 否 |
| state pull | 下载完整状态 JSON | 否 |
| state mv | 移动/重命名资源地址 | 是 |
| state rm | 从状态中移除资源记录 | 是 |
| state replace-provider | 替换状态中的 provider 来源 | 是 |

## 关键要点

- state mv 只修改状态中的地址，不影响远端资源，也不触发销毁重建
- state rm 让 Terraform "忘记"资源，远端对象不受影响
- 写入操作执行前务必使用 -dry-run 预览
- 所有写入操作会自动创建 .tfstate.backup 备份
- Terraform 1.1+ 推荐用 moved 块替代 state mv
- Terraform 1.7+ 推荐用 removed 块替代 state rm
- state rm 和 import 互为逆操作

## Azure 视角的额外提示

- Azure 资源 ID 是 /subscriptions/.../resourceGroups/.../providers/.../<name> 的完整路径，比 AWS 的 ARN 更长；做 import / state list -id 时需要写完整路径。
- azurerm provider v4 中，metadata_host、resource_provider_registrations = "none" 等参数让 provider 指向 miniblue 模拟器，无需真实 Azure 凭据。
- 使用 azlocal 验证远端资源（如 azlocal network vnet subnet list、azlocal group list）比直接调用 ARM REST API 更直观。
