# 恭喜完成 terraform show 实战练习！

## 知识总结

| 功能 | 命令 | 核心场景 |
|------|------|---------|
| 查看当前状态 | terraform show | 全局审查受管资源的完整属性 |
| 查看计划文件 | terraform show tfplan | 审查已保存的执行计划（二进制→人类可读） |
| 状态 JSON 输出 | terraform show -json | 脚本提取资源清单、属性值 |
| 计划 JSON 输出 | terraform show -json tfplan | CI/CD 自动分析变更、判断危险操作 |
| 去除颜色输出 | terraform show -no-color tfplan | 导出纯文本到审计日志或 PR 评论 |

## show 与相关命令的定位

| 命令 | 定位 |
|------|------|
| terraform show | 完整状态/计划的全量展示 |
| terraform state list | 只列资源地址，快速定位 |
| terraform state show ADDR | 单个资源详情，定点排查 |
| terraform output | 只查看 output 值 |

## 重要提醒

- 计划文件是二进制格式，只能用 terraform show 解读
- -json 输出中敏感值以明文显示，注意保护输出内容
- terraform show 是纯只读命令，不会修改任何状态或资源
