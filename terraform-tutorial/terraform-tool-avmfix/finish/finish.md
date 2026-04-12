# 恭喜完成！

你已经体验了 avmfix 的自动修复能力：

- **resource/data 块内排序**：元参数在前，普通属性按 Schema 顺序，lifecycle/depends_on 在后
- **variable 块排序**：type → default → description → validation
- **output 块排序**：按名称字母序排列
- **locals 排序**：按名称字母序排列
- **文件归位**：variable 移入 variables.tf，output 移入 outputs.tf
- **冗余声明清理**：移除 nullable = true 和 sensitive = false 等默认值声明

## 推荐工作流

```
avmfix -folder .     # 1. 规范化排序和文件归位
terraform fmt        # 2. 格式化缩进和对齐
terraform validate   # 3. 验证语法正确性
```

## 延伸阅读

- [avmfix GitHub](https://github.com/lonegunmanb/avmfix)
- [avmfix 详解（Terraform 模块之道）](https://lonegunmanb.github.io/dao-of-terraform-modules/%E5%B7%A5%E5%85%B7%E9%93%BE/avmfix.html)
- [Azure Verified Modules 规范](https://aka.ms/avm)
