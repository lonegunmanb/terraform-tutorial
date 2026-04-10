# 第二步：import 块——声明式批量导入

## 命令行 import 的局限

上一步用 terraform import 命令导入了一个桶。这种方式每次只能导入一个资源，没有预览，而且导入记录不留在代码中。

从 Terraform v1.5 开始，可以使用 import 块在配置中声明要导入的资源，享受以下优势：

- terraform plan 阶段可预览导入效果
- 一次 apply 可导入多个资源
- 导入操作留在代码提交记录中

## 查看预置的 import 块配置

工作目录的 /root 下已经预置了 import-block.tf 文件，查看其内容：

```
cat /root/import-block.tf
```

文件中声明了两个 resource 块（logs 和 archive）以及对应的两个 import 块。将它复制到工作目录：

```
cp /root/import-block.tf .
```

## 用 plan 预览导入

运行 plan 查看导入预览：

```
terraform plan
```

plan 的输出中会显示 import 标记，表明这些资源将被导入而非新建。这是 import 块相比命令行 import 最大的优势——可以在执行前审查。

## 执行导入

确认 plan 无误后执行：

```
terraform apply -auto-approve
```

输出显示两个资源同时被导入。确认状态：

```
terraform state list
```

三个桶（app、logs、archive）现在都在 Terraform 管理中。

## 清理 import 块

导入完成后，import 块的使命就结束了。在后续的 plan 中，已经导入的资源的 import 块不会再有任何效果，但为了保持配置整洁，通常会删除它们：

```
sed -i '/^import {/,/^}/d' import-block.tf
cat import-block.tf
```

验证删除 import 块后 plan 没有变化：

```
terraform plan
```

显示 No changes——资源已在状态中，import 块已安全移除。

进入下一步学习导入到 for_each 资源。
