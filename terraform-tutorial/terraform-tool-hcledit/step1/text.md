# attribute 与 block 操作：读取、修改、删除 HCL 配置

## 验证安装

进入工作目录，确认 hcledit 已安装：

```
cd /root/workspace
hcledit version
```

查看当前配置文件：

```
cat main.tf
```

## attribute get：读取属性

读取 app 桶的 bucket 属性值：

```
hcledit attribute get resource.aws_s3_bucket.app.bucket -f main.tf
```

输出的是 HCL 原始表达式（含引号和插值）。

读取嵌套块中的属性——DynamoDB 表的 hash_key：

```
hcledit attribute get resource.aws_dynamodb_table.sessions.hash_key -f main.tf
```

读取 provider 块中的属性：

```
hcledit attribute get provider.aws.region -f main.tf
```

读取 terraform 块中嵌套较深的属性：

```
hcledit attribute get terraform.required_version -f main.tf
```

## attribute set：修改属性

先用管道模式预览变更（不修改文件）：

```
cat main.tf | hcledit attribute set provider.aws.region '"ap-northeast-1"'
```

对比原文件，只有 region 发生了变化，注释和其他属性完整保留。

现在用 -f 和 -u 原地修改——把 DynamoDB 的计费模式改为预置容量：

```
hcledit attribute set resource.aws_dynamodb_table.sessions.billing_mode '"PROVISIONED"' -f main.tf -u
```

验证修改：

```
hcledit attribute get resource.aws_dynamodb_table.sessions.billing_mode -f main.tf
```

改回去：

```
hcledit attribute set resource.aws_dynamodb_table.sessions.billing_mode '"PAY_PER_REQUEST"' -f main.tf -u
```

## attribute append：追加属性

给 app 桶追加 force_destroy 属性：

```
cat main.tf | hcledit attribute append resource.aws_s3_bucket.app.force_destroy 'true' --newline
```

注意输出中 force_destroy = true 出现在 app 桶块内。--newline 在前面加了一行空行。

用 -u 真正追加到文件：

```
hcledit attribute append resource.aws_s3_bucket.app.force_destroy 'true' --newline -f main.tf -u
```

验证：

```
hcledit attribute get resource.aws_s3_bucket.app.force_destroy -f main.tf
```

## attribute rm：删除属性

删除刚才追加的 force_destroy：

```
hcledit attribute rm resource.aws_s3_bucket.app.force_destroy -f main.tf -u
```

确认已删除（下面的命令应该没有输出）：

```
hcledit attribute get resource.aws_s3_bucket.app.force_destroy -f main.tf
```

## block list：列出所有块

```
hcledit block list -f main.tf
```

输出所有顶层块的地址，例如 terraform、provider.aws、resource.aws_s3_bucket.app 等。

## block get：获取完整块

```
hcledit block get resource.aws_s3_bucket.app -f main.tf
```

输出包含块头、花括号和所有内部属性。对比 body get，它只返回块体：

```
hcledit body get resource.aws_s3_bucket.app -f main.tf
```

## block new：创建新块

在 main.tf 末尾创建一个空的 S3 桶资源块：

```
hcledit block new resource.aws_s3_bucket.archive --newline -f main.tf -u
```

验证：

```
hcledit block list -f main.tf | grep archive
hcledit block get resource.aws_s3_bucket.archive -f main.tf
```

给新块添加属性：

```
hcledit attribute append resource.aws_s3_bucket.archive.bucket '"myapp-dev-archive"' -f main.tf -u
hcledit attribute append resource.aws_s3_bucket.archive.tags 'local.common_tags' -f main.tf -u
```

查看完整的块：

```
hcledit block get resource.aws_s3_bucket.archive -f main.tf
```

## block rm：删除块

删除刚才创建的 archive 桶：

```
hcledit block rm resource.aws_s3_bucket.archive -f main.tf -u
```

验证：

```
hcledit block list -f main.tf | grep archive
```

没有输出，说明块已被删除。

## block mv：重命名块

把 logs 桶重命名为 audit_logs：

```
cat main.tf | hcledit block mv resource.aws_s3_bucket.logs resource.aws_s3_bucket.audit_logs
```

预览输出后确认无误，原地修改：

```
hcledit block mv resource.aws_s3_bucket.logs resource.aws_s3_bucket.audit_logs -f main.tf -u
```

验证：

```
hcledit block list -f main.tf | grep s3_bucket
```

改回去（保持文件一致）：

```
hcledit block mv resource.aws_s3_bucket.audit_logs resource.aws_s3_bucket.logs -f main.tf -u
```

## 管道组合：批量操作

hcledit 的管道能力让批量操作非常方便。例如，列出所有资源块并统计数量：

```
hcledit block list -f main.tf | grep '^resource\.' | wc -l
```

提取所有资源块的类型：

```
hcledit block list -f main.tf | grep '^resource\.' | cut -d. -f2 | sort -u
```

读取 variables.tf 中所有变量的默认值：

```
for var in $(hcledit block list -f variables.tf | grep '^variable\.'); do
  name=$(echo "$var" | cut -d. -f2)
  default=$(hcledit attribute get "${var}.default" -f variables.tf 2>/dev/null)
  echo "${name} = ${default}"
done
```

---

## 练习

请完成以下任务：

1. 使用 hcledit 读取 outputs.tf 中 app_bucket 输出的 description 属性值
2. 使用 hcledit 给 main.tf 中的 logs 桶追加 force_destroy = true 属性（用 -u 原地修改）
3. 使用 hcledit 在 main.tf 中新建一个空块 resource.aws_s3_bucket.backup，然后给它添加 bucket 属性值为 "myapp-dev-backup" 和 tags 属性值为 local.common_tags
4. 使用 hcledit 和管道组合，一条命令列出 main.tf 中所有资源的完整地址和类型

完成后查看参考答案：

```
cat <<'ANSWER'
# 练习参考答案

# 1. 读取 description
hcledit attribute get output.app_bucket.description -f outputs.tf

# 2. 追加 force_destroy
hcledit attribute append resource.aws_s3_bucket.logs.force_destroy 'true' -f main.tf -u

# 3. 新建 backup 桶
hcledit block new resource.aws_s3_bucket.backup --newline -f main.tf -u
hcledit attribute append resource.aws_s3_bucket.backup.bucket '"myapp-dev-backup"' -f main.tf -u
hcledit attribute append resource.aws_s3_bucket.backup.tags 'local.common_tags' -f main.tf -u

# 4. 列出资源地址和类型
hcledit block list -f main.tf | grep '^resource\.' | while read addr; do
  type=$(echo "$addr" | cut -d. -f2)
  echo "$addr -> $type"
done
ANSWER
```

验证练习 2 和 3：

```
hcledit attribute get resource.aws_s3_bucket.logs.force_destroy -f main.tf
hcledit block get resource.aws_s3_bucket.backup -f main.tf
```
