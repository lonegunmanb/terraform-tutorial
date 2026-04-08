# 恭喜你完成了 terraform init 实战练习！

## 你已掌握的知识

| 知识点 | 要点 |
|--------|------|
| terraform init 的作用 | 初始化工作目录：backend、模块、provider |
| .terraform/ 目录 | 缓存已下载的 provider 插件和模块代码 |
| .terraform.lock.hcl | 锁定 provider 版本和校验和，应提交到代码仓库 |
| 幂等性 | terraform init 可安全重复执行，不会破坏资源或状态 |
| -upgrade | 重新检查并升级 provider 到最新兼容版本 |
| -lockfile=readonly | CI/CD 中禁止修改锁文件，确保版本一致性 |
| -migrate-state | 切换 backend 时将现有状态迁移到新 backend |
| -force-copy | 配合 -migrate-state 跳过交互式确认 |
| -reconfigure | 重置 backend 配置，跳过状态迁移 |

## 下一步

继续阅读 Terraform CLI 章节，学习其他子命令的用法。
