# 恭喜完成！

你已经掌握了 Terraform 批量导入的核心技能：

- **import + for_each**：手动声明资源 ID 映射，批量导入已知资源
- **.tfquery.hcl + terraform query**：自动发现未管理的资源
- **-generate-config-out**：自动生成 import + resource 块
- **参数化查询**：使用 variable 让查询配置可复用
- **DynamoDB 等复杂资源导入**：用 object 映射处理属性差异

## 工作流总结

| 场景 | 推荐方式 |
|------|---------|
| 少量已知资源 | import 块 + 手动编写 resource |
| 同类型批量资源 | import for_each + locals 映射 |
| 大规模未知资源 | terraform query + generate-config-out |
| 混合场景 | 先 query 发现，再重构为 for_each |

## 延伸阅读

- [Import existing resources in bulk](https://developer.hashicorp.com/terraform/language/import/bulk)
- [list block reference](https://developer.hashicorp.com/terraform/language/block/tfquery/list)
- [terraform query command](https://developer.hashicorp.com/terraform/cli/commands/query)
- [代码重构 — import 块](/refactor_module#import-块)
