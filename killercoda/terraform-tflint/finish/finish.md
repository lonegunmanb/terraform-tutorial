# 🎉 实验完成！

你已经掌握了 TFLint 的核心用法：

| 操作 | 命令 |
|------|------|
| 初始化插件 | `tflint --init` |
| 运行检查 | `tflint` |
| 指定配置 | `tflint --config .tflint.hcl` |

## 你修复了这些问题

- ✅ 变量缺少 `description`
- ✅ 命名不符合 `snake_case` 约定
- ✅ 存在未使用的变量声明
- ✅ 使用了废弃的资源属性

## 在 CI/CD 中使用

在 GitHub Actions 中加入 TFLint 检查：

```yaml
- name: TFLint
  run: |
    tflint --init
    tflint --format compact
```

## 下一步

返回教程主页，继续学习 **模块化实践** 章节。
