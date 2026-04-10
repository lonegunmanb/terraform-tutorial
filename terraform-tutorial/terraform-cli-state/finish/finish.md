# 恭喜完成 terraform state 实战练习！

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
