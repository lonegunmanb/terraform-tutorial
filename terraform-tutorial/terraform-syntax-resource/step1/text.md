# 第一步：资源基础 — S3 存储桶与对象

在这一步中，你将创建一个简单的"静态网站托管"场景，学习 resource 块的基本语法、资源属性引用和资源间的依赖关系。

## 查看代码

```bash
cd /root/workspace/step1
cat main.tf
```

观察代码中的关键点：

- **resource 块语法** — `resource "类型" "名称" { ... }`，两个标签分别是资源类型和本地名称
- **属性引用** — `aws_s3_bucket.website.id` 引用桶的 ID，传递给 `aws_s3_object`
- **隐式依赖** — `aws_s3_object.index` 引用了 `aws_s3_bucket.website.id`，Terraform 自动确保先创建桶
- **Heredoc** — 使用 `<<-HTML ... HTML` 嵌入多行 HTML 内容

## 执行 Plan

先看看 Terraform 计划创建哪些资源：

```bash
terraform plan
```

观察输出中：
- `+` 号表示将要创建的资源
- 每个资源显示其类型、名称和参数
- 有些属性标记为 `(known after apply)` — 这些是资源创建后才能获得的输出属性

## 执行 Apply

```bash
terraform apply -auto-approve
```

成功后观察输出值：
- `bucket_id` — S3 桶的 ID
- `bucket_arn` — S3 桶的 ARN（Amazon Resource Name）
- `index_page_etag` — 上传文件的内容哈希
- `queue_url` 和 `queue_arn` — SQS 队列的 URL 和 ARN

## 验证资源

使用 AWS CLI（通过 LocalStack）验证创建的资源：

```bash
# 列出所有 S3 桶
awslocal s3 ls

# 列出桶中的对象
awslocal s3 ls s3://my-tutorial-website/

# 查看首页内容
awslocal s3 cp s3://my-tutorial-website/index.html -

# 列出 SQS 队列
awslocal sqs list-queues
```

## 查看状态

```bash
# 查看状态文件中的所有资源
terraform state list

# 查看某个资源的详细状态
terraform state show aws_s3_bucket.website
```

## 修改并更新

试着修改 index.html 的内容，体验 Terraform 的更新行为：

```bash
sed -i 's/Hello from Terraform!/Hello from Terraform v2!/' main.tf
terraform plan
```

注意 Terraform 只会更新发生变化的资源（`aws_s3_object.index`），不会影响其他资源。

```bash
terraform apply -auto-approve
```

## 关键点

- resource 块有两个标签：资源类型和本地名称
- 通过 `<类型>.<名称>.<属性>` 引用资源的输出属性
- Terraform 自动分析表达式中的引用来确定依赖顺序
- `terraform plan` 预览变更，`terraform apply` 执行变更
- 只有发生变化的资源才会被更新

完成后继续下一步。
