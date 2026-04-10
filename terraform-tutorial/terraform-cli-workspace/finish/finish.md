# 恭喜完成 terraform workspace 实战练习！

## 知识总结

| 功能 | 命令 | 核心场景 |
|------|------|---------|
| 查看当前 workspace | terraform workspace show | 确认当前操作环境 |
| 列出所有 workspace | terraform workspace list | 查看全部环境，星号标记当前 workspace |
| 创建并切换 | terraform workspace new NAME | 创建临时测试环境 |
| 切换 workspace | terraform workspace select NAME | 在已有 workspace 间切换 |
| 删除 workspace | terraform workspace delete NAME | 清理不再使用的环境 |
| 强制删除 | terraform workspace delete -force NAME | 不销毁资源直接删除（产生悬空资源） |
| 使用 workspace 名称 | terraform.workspace | 在配置中区分不同环境的资源名称 |

## 状态隔离要点

- 每个 workspace 有独立的 state，资源互不可见
- 所有 workspace 共享同一份 .tf 配置文件
- 本地 state 存储：default 在根目录，其他在 terraform.tfstate.d/NAME/ 下
- 配置变更对所有 workspace 可见，但 state 各自独立

## CLI workspace 与 HCP Terraform workspace 的区别

这是一个非常容易混淆的概念，务必牢记：

- CLI workspace：同一工作目录下的多份 state 实例，共享配置和 backend 凭证，隔离程度弱
- HCP Terraform workspace：各有独立的配置、变量、凭证、权限和运行历史，相当于完全独立的工作目录

生产环境中需要不同凭证和访问控制的多环境管理（dev/staging/prod），不应使用 CLI workspace，而应使用 HCP Terraform workspace 或为每个环境创建独立配置目录。
