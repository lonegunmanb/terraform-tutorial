# 恭喜完成 terraform import 实战练习！

## 知识总结

| 功能 | 方式 | 核心场景 |
|------|------|---------|
| 导入单个资源 | terraform import ADDR ID | 临时导入、快速接管 |
| 导入到 count 资源 | terraform import 'ADDR[0]' ID | 多实例资源按索引导入 |
| 导入到 for_each 资源 | terraform import 'ADDR["key"]' ID | 多实例资源按 key 导入 |

## 导入工作流

```
1. 在配置中声明 resource 块（可以是空的）
2. 执行 terraform import
3. 运行 terraform plan 查看差异
4. 补全配置直到 plan 显示 No changes
```

## 关键要点

- terraform import 不会自动生成配置，需要手动编写 resource 块
- 每个远端资源只能导入到一个 Terraform 资源地址
- 导入后务必运行 terraform plan 验证一致性
- 声明式 import 块的用法请参考代码重构章节
