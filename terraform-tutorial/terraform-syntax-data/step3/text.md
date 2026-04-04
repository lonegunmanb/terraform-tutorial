# 第三步：小测验 — 补全 data 块

在这一步中，你将亲手编写 data 块来检验自己对数据源的理解。main.tf 中已经提供了资源和输出，但缺少 4 个 data 块——你需要补全它们，然后用 terraform test 验证你的答案。

## 查看代码

```bash
cd /root/workspace/step3
cat main.tf
```

观察代码结构：

- 上半部分是**已提供的资源**：一个 S3 桶、一个 S3 对象、一个 SQS 队列
- 中间有 4 道题目，每道题要求你添加一个 data 块（注释中标明了类型、名称和文档链接）
- 下半部分是**已提供的输出**，它们引用了你需要补全的 data 块

现在直接运行 plan 会报错，因为 output 引用的 data 块还不存在：

```bash
terraform init
terraform plan
```

你会看到类似这样的错误：

```
Error: Reference to undeclared resource
  A data resource "aws_region" "current" has not been declared in the root module.
```

## 完成题目

阅读 main.tf 中每道题目的注释，参考注释里的文档链接，在指定位置添加对应的 data 块。

**第 1 题**：添加 `data "aws_region" "current"`，查询当前区域（无需参数）

**第 2 题**：添加 `data "aws_caller_identity" "current"`，查询调用者身份（无需参数）

**第 3 题**：添加 `data "aws_s3_bucket" "web_lookup"`，通过桶名反查 S3 桶（需要 `bucket` 参数）

**第 4 题**：添加 `data "aws_sqs_queue" "tasks_lookup"`，通过队列名反查 SQS 队列（需要 `name` 参数）

用编辑器或命令行编辑 main.tf，在每道题目下方的空白处写入你的代码。

## 验证答案

补全所有 data 块后，先确认 plan 不再报错：

```bash
terraform plan
```

然后用 terraform test 运行自动化测试：

```bash
terraform test
```

如果所有 data 块都正确，你会看到：

```
data_test.tftest.hcl... in progress
  run "test_region"... pass
  run "test_account_id_not_empty"... pass
  run "test_bucket_lookup_arn"... pass
  run "test_queue_lookup_arn"... pass
  run "test_queue_lookup_url"... pass
data_test.tftest.hcl... tearing down
data_test.tftest.hcl... pass

Success! 5 passed, 0 failed.
```

terraform test 会自动创建资源、运行断言、最后销毁——不需要手动 apply 和 destroy。

如果某道题写错了，测试会告诉你哪个断言失败。根据错误信息修正 main.tf 后重新运行 terraform test 即可。

## 关键点

- data 块的语法是 `data "类型" "名称" { ... }`
- 有些数据源不需要查询参数（如 aws_region、aws_caller_identity）
- 反查已有资源时，需要提供标识参数（如桶名、队列名）
- data 引用已有资源属性时，读取会推迟到 apply 阶段

恭喜你完成了数据源的学习！

再次运行测试：

```bash
terraform test
```

你应该看到 5 道题全部通过！

## 关键点

- terraform test 使用 .tftest.hcl 文件定义测试用例
- 每个 run 块是一个独立的测试步骤，可以包含多个 assert 断言
- terraform test 自动管理资源的创建和销毁
- 结合 data 和 output 可以方便地验证基础设施的正确性
- data 查询的结果可以在 assert 中用于断言验证

恭喜你完成了数据源的学习！
