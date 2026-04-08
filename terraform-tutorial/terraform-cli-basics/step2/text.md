# 第二步：terraform fmt — 代码格式化

## 查看待格式化的文件

工作目录中预置了一个缩进混乱的文件。先查看它的内容：

```bash
cd /root/workspace
cat unformatted.tf
```

你会看到属性对齐、缩进不一致等问题。

## 检查模式：不修改文件

只检查哪些文件需要格式化，不修改任何文件：

```bash
terraform fmt -check
```

命令退出码为非零，并列出需要格式化的文件名。这个模式适合放在 CI 流水线里做强制检查。

## 预览改动 diff

查看具体会改动哪些内容，但不实际修改文件：

```bash
terraform fmt -diff
```

输出中 + 行是格式化后的内容，- 行是原始内容。

## 执行格式化

一键修复所有 .tf 文件的格式：

```bash
terraform fmt
```

输出会列出被修改的文件名。

## 验证结果

再次运行检查模式，确认所有文件已符合标准格式：

```bash
terraform fmt -check && echo "格式检查通过"
```

此时命令应以退出码 0 成功退出。

查看格式化后的文件内容，属性对齐和缩进均已统一：

```bash
cat unformatted.tf
```

## 递归格式化

如果配置有子目录，可以加 -recursive 一并处理：

```bash
terraform fmt -recursive
```

这会递归格式化 modules/ 下的所有 .tf 文件。
