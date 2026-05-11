# 🎉 实验完成！

你已经掌握了 Terraform CLI 工具中的常用辅助命令（Azure 版）：

| 命令 | 用途 |
|------|------|
| `terraform version` | 查看版本，检测更新 |
| `terraform -install-autocomplete` | 安装 bash/zsh 命令补全 |
| `terraform -chdir=PATH <cmd>` | 不切换目录直接操作指定路径 |
| `terraform fmt` | 格式化 `.tf` 文件为标准风格 |
| `terraform fmt -check` | 检查格式是否合规（CI 适用） |
| `terraform fmt -diff` | 预览格式变更内容 |
| `terraform console` | 交互式求值 HCL 表达式和函数 |
| `terraform get` | 下载/更新 module 块引用的模块 |
| `terraform graph` | 输出资源依赖图（DOT 格式） |
| `terraform force-unlock LOCK_ID` | 解除残留的孤儿状态锁 |

## 关键技巧回顾

- **fmt -check in CI**：将 `terraform fmt -check` 加入流水线，有格式问题即报错，强制统一代码风格
- **console 调试**：遇到不熟悉的内置函数或复杂 `for` 表达式，先在 console 里验证逻辑
- **get vs init**：只新增了 `module` 块时，用 `terraform get` 比完整 `terraform init` 更轻量
- **force-unlock 的时机**：只有确认没有其他 Terraform 进程仍在运行时才执行；生产环境建议加监控避免出现孤儿锁

## Azure 版要点回顾

- 本课程通过 [miniblue](https://miniblue.io/) 在本地完整模拟 Azure 控制平面，azurerm provider 走 `metadata_host = "localhost:4567"` 的 HTTPS 端点
- CLI 基础命令（fmt / console / get / graph）本身与具体 provider 无关——同样的命令换成 azurerm 配置依然完全适用，这正是 Terraform 多云抽象的价值
- `force-unlock` 演示用本地 backend + 长时 apply + `kill -9`，比单纯伪造锁文件更接近真实事故；如果使用 azurerm backend（Azure Blob Storage），则锁是以 blob lease 形式存在，故障表现和清理方式略有不同

## 下一步

返回教程主页，继续学习资源生命周期管理——`init`、`plan`、`apply`、`destroy` 等核心子命令将在专属章节中深入讲解。其中 `apply` 已经有同款的 [Azure 版动手实验](https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-cli-apply-azure)，可作为进阶练习。
