# 恭喜完成 terraform import 实战练习！

## 知识总结

| 功能 | 方式 | 核心场景 |
|------|------|---------|
| 导入单个资源 | terraform import ADDR ID | 临时导入、快速接管 |
| 声明式导入 | import 块 + terraform apply | CI/CD 友好、可预览、可批量 |
| 导入到 count 资源 | terraform import 'ADDR[0]' ID | 多实例资源按索引导入 |
| 导入到 for_each 资源 | terraform import 'ADDR["key"]' ID | 多实例资源按 key 导入 |

## 导入工作流

```
1. 在配置中声明 resource 块（可以是空的）
2. 执行 terraform import 或使用 import 块
3. 运行 terraform plan 查看差异
4. 补全配置直到 plan 显示 No changes
5. 删除 import 块（如使用声明式方式）
```

## 关键要点

- terraform import 不会自动生成配置，需要手动编写 resource 块
- 每个远端资源只能导入到一个 Terraform 资源地址
- 导入后务必运行 terraform plan 验证一致性
- 从 v1.5 开始推荐使用 import 块，支持 plan 预览和批量导入
- import 块在完成导入后应删除，保持配置整洁
