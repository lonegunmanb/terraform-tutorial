# 恭喜完成！

你已经掌握了 terraform-docs 的核心用法：

- **多种输出格式**：markdown table、json、pretty、tfvars hcl
- **README 注入**：用 BEGIN_TF_DOCS / END_TF_DOCS 标记实现文档与自定义内容共存
- **配置文件**：.terraform-docs.yml 定制格式、排序、输出文件
- **内容模板**：content 字段完全控制文档结构和区块顺序
- **区块显隐**：sections.hide / sections.show 控制哪些信息出现在文档中
- **幂等性检查**：CI 中通过 diff 确保文档始终最新

## 推荐工作流

```
terraform-docs .       # 1. 生成/更新文档
avmfix -folder .       # 2. 规范化代码排序
terraform fmt          # 3. 格式化缩进对齐
git add -A && git commit  # 4. 提交
```

## 延伸阅读

- [terraform-docs 官网](https://terraform-docs.io/)
- [terraform-docs GitHub](https://github.com/terraform-docs/terraform-docs)
- [配置文件参考](https://terraform-docs.io/user-guide/configuration/)
- [terraform-docs 详解（Terraform 模块之道）](https://lonegunmanb.github.io/dao-of-terraform-modules/%E5%B7%A5%E5%85%B7%E9%93%BE/terraform-docs.html)
