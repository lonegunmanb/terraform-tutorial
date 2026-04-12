# avmfix 实战

通过本节实验，你将体验 avmfix 如何自动修复 Terraform 模块中的代码规范问题。

## 实验场景

工作目录中有一个故意打乱格式的 Terraform 模块：

- resource 块内属性顺序不规范（tags 在最前面、depends_on 在中间）
- variable 块的 type/default/description 顺序不一致
- output 块放在 main.tf 而非 outputs.tf
- variable 块散落在 main.tf 中
- locals 没有按字母序排列
- 存在冗余声明（nullable = true、sensitive = false）

你将使用 avmfix 一键修复所有这些问题。

## 学习内容

| 内容 | 说明 |
|------|------|
| resource/data 块排序 | 元参数在前，普通属性按 Schema 顺序，lifecycle/depends_on 在后 |
| variable/output 块排序 | type/default/description 正确顺序，output 按字母序 |
| 文件归位 | variable 移至 variables.tf，output 移至 outputs.tf |
| 冗余清理 | 移除不必要的 nullable = true 和 sensitive = false |
| locals 排序 | 按字母序排列 |

点击右侧箭头开始实验。
