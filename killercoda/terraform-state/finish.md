# 🎉 实验完成！

你已经掌握了 Terraform 状态管理的核心操作：

| 命令 | 作用 |
|------|------|
| `terraform state list` | 列出所有已管理的资源 |
| `terraform state show` | 查看资源详细属性 |
| `terraform state mv` | 重命名/移动资源（不销毁重建） |
| `terraform state rm` | 从状态中移除资源（不销毁真实资源） |

## 关键要点

- 状态文件是 Terraform 的"记忆"，它记录了代码与真实资源的映射关系
- `state mv` 是重构代码时的救命工具——避免不必要的资源重建
- `state rm` 用于"接管"或"释放"资源的管理权
- 在团队协作中，应使用远程后端存储状态文件

## 下一步

返回教程主页，继续学习 **TFLint 代码检查** 章节。
