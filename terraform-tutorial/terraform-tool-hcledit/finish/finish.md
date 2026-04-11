# 恭喜完成！

你已经掌握了 hcledit 的核心用法：

- **attribute get / set**：读取和修改属性值
- **attribute append / rm**：追加和删除属性
- **attribute mv / replace**：重命名属性、同时修改属性名和值
- **block list / get / new / rm / mv**：列出、查看、创建、删除、重命名块
- **body get**：获取块体内容（不含块头）
- **-f / -u**：文件模式与原地修改
- **管道组合**：与 grep、cut、while 等命令配合批量操作

## 何时使用 hcledit

| 场景 | 推荐工具 |
|------|---------|
| CI/CD 中批量修改版本号、标签 | hcledit |
| 手动编辑单个配置文件 | 编辑器 |
| 复杂的代码重构（移动资源到模块） | terraform mv + 编辑器 |
| 提取配置信息到脚本中 | hcledit attribute get |
| 代码格式化 | terraform fmt（更权威） |

## 延伸阅读

- [hcledit GitHub](https://github.com/minamijoyo/hcledit)
- [hcledit Releases](https://github.com/minamijoyo/hcledit/releases)
