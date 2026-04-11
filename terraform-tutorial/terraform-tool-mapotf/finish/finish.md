# 恭喜完成！

你已经掌握了 mapotf 的核心用法：

- **data 块匹配**：按资源类型（如 aws_vpc）精确匹配 Terraform 配置中的资源
- **transform 块变更**：用 update_in_place 和 asstring 为资源动态添加 lifecycle.ignore_changes
- **transform 模式**：修改文件、审查 diff、手动执行
- **apply 模式**：转换 → 执行 → 自动还原，适合 CI/CD
- **多资源匹配**：用 locals + merge 组合多个 data 块结果，一套规则覆盖多种资源

## 何时使用 mapotf

| 场景 | 是否适合 |
|------|---------|
| 为第三方模块中的资源添加 ignore_changes | 最佳用例 |
| 批量为所有资源注入通用标签 | 适合 |
| Provider 大版本升级的自动化重构 | 适合 |
| 组织级治理规则的集中管理 | 适合 |
| 简单的单属性修改 | 不如 hcledit 直接 |
| 编写新的 Terraform 配置 | 不适合（mapotf 是改配置，不是写配置） |

## 延伸阅读

- [mapotf GitHub](https://github.com/Azure/mapotf)
- [mapotf 示例：ignore_changes](https://github.com/lonegunmanb/mapotf_demo/tree/main/ignore_changes)
- [mapotf 详解（Terraform 模块之道）](https://lonegunmanb.github.io/dao-of-terraform-modules/%E5%B7%A5%E5%85%B7%E9%93%BE/mapotf.html)
