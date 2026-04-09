# 恭喜完成 terraform apply 实战练习！

## 知识总结

| 功能 | 命令 / 参数 | 核心场景 |
|------|------------|---------|
| 创建/变更资源（交互确认） | terraform apply | 日常开发，人工审批变更 |
| 跳过确认 | terraform apply -auto-approve | 自动化流水线 |
| 保存计划 | terraform plan -out=tfplan | CI/CD 两步工作流（生成阶段） |
| 执行保存的计划 | terraform apply tfplan | CI/CD 两步工作流（执行阶段），无需再次确认 |
| 定向 apply | terraform apply -target=ADDR -auto-approve | 应急修复单个资源 |
| 强制重建 | terraform apply -replace=ADDR -auto-approve | 修复内部状态损坏的资源，替代 terraform taint |
| 销毁模式 | terraform apply -destroy -auto-approve | 销毁全部或指定资源 |
| 只更新 state | terraform apply -refresh-only -auto-approve | 将 state 与带外变更对齐，不操作实际资源 |
| 机器可读输出 | terraform apply -json -auto-approve | CI 日志结构化采集与解析 |

## 重要提醒

- 生产环境推荐两步工作流（plan -out → apply tfplan），确保执行的是经过人工评审的计划
- 计划文件包含完整的变量值（含敏感数据），应视为敏感制品，按需加密存储
- -target 和 -replace 是应急手段，用后应立即执行完整 apply 以消除 state 与配置的差距
- -refresh-only 不修改任何实际资源，只更新 state 文件，是处理带外变更的安全工具
