# 第一步：查看当前状态

## 查看完整状态

进入工作目录，用 terraform show 查看当前状态中所有受管资源的属性：

```
cd /root/workspace
terraform show
```

输出包含每个资源的完整属性（bucket 名、ARN、tags 等）以及所有 output 的值。这是检视"Terraform 眼中的基础设施当前样貌"的最直接方式。

## 对比 state list 和 state show

terraform show 输出所有资源的全部属性，信息量很大。如果只想快速查看有哪些资源，可以用 state list：

```
terraform state list
```

输出仅列出资源地址，不包含属性细节。

要查看某个特定资源的属性，用 state show：

```
terraform state show aws_s3_bucket.app
```

对比三者的定位：

- show：展示整个状态的完整信息，适合全局审查
- state list：只列资源地址，适合快速定位
- state show ADDR：展示单个资源详情，适合定点排查

## 用 grep 快速检索

状态中资源较多时，可以结合 grep 快速定位关键信息：

```
terraform show | grep bucket
```

列出所有包含 bucket 的行——快速确认桶名是否符合预期。

查看某个资源块的完整属性（输出该行及后续 10 行）：

```
terraform show | grep -A 10 "aws_dynamodb_table.sessions"
```

## 查看 output 值

terraform show 的输出末尾包含所有 output 的值。也可以用专门的 output 命令只查看 output：

```
terraform output
```

对比可以发现，terraform show 展示的信息是 state list + state show + output 的超集。

进入下一步学习如何查看计划文件。
