# 恭喜完成 terraform plan 实战练习！

## 知识总结

| 功能 | 命令 / 参数 | 核心场景 |
|------|------------|---------|
| 预览变更 | terraform plan | 日常开发前的必做步骤 |
| 无变更检测 | Plan: 0 to add... | 确认配置与远端一致 |
| 预览全量销毁 | terraform plan -destroy | 执行 destroy 前的安全确认 |
| 对齐带外变更 | terraform plan -refresh-only | 有人在 Terraform 外手动变更了资源 |
| 保存计划文件 | terraform plan -out=tfplan | CI/CD 两步工作流（plan → approve → apply） |
| 查看计划文件 | terraform show tfplan | 以可读格式查看已保存的计划 |
| 定向规划 | terraform plan -target=ADDR | 故障恢复等特殊场景，非常规使用 |
| 强制重建 | terraform plan -replace=ADDR | 替代 terraform taint |
| 命令行变量 | terraform plan -var 'k=v' | 临时覆盖单个变量 |
| 变量文件 | terraform plan -var-file=f.tfvars | 多变量批量注入 |
| 三态退出码 | terraform plan -detailed-exitcode | 脚本化判断是否有变更 |

## 重要提醒

- 计划文件（-out 产生的文件）包含完整的变量值（含敏感数据），请视为敏感制品
- -target 是应急手段，不是日常工具
- 在 CI 中推荐组合：terraform plan -out=tfplan -input=false -no-color -detailed-exitcode
