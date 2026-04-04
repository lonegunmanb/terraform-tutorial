# 第二步：小测验 — 补全 check 块

在这一步中，你将亲手编写 check 块来检验自己的理解。main.tf 中已经提供了资源和输出，但缺少 3 个 check 块——你需要补全它们，然后用 terraform test 验证你的答案。

## 查看代码

```bash
cd /root/workspace/step2
cat main.tf
```

观察代码结构：

- 上半部分是**已提供的资源**：一个带标签的 S3 桶、一个 S3 对象、一个 SQS 队列
- 中间有 3 道题目，每道题要求你添加一个 check 块（注释中标明了名称、条件和错误信息）
- 下半部分是**已提供的输出**

## 初始化

```bash
terraform init
```

## 完成题目

阅读 main.tf 中每道题目的注释，在指定位置添加对应的 check 块。

**第 1 题**：添加一个 check 块，验证 S3 桶设置了 ManagedBy 标签

```
check "bucket_managed_tag" {
  assert {
    condition     = ...你的条件...
    error_message = "S3 桶缺少 ManagedBy 标签。"
  }
}
```

**第 2 题**：添加一个 check 块，验证 SQS 队列的消息保留时间至少为 1 天

```
check "queue_retention" {
  assert {
    condition     = ...你的条件...
    error_message = "SQS 队列的消息保留时间不足 1 天。"
  }
}
```

**第 3 题**：添加一个 check 块，包含一个**有限作用域的数据源**和一个断言

```
check "bucket_has_config" {
  data "aws_s3_object" "config_lookup" {
    ...数据源参数...
  }

  assert {
    condition     = ...你的条件...
    error_message = "配置文件 config.json 内容为空。"
  }
}
```

用编辑器编辑 main.tf，在每道题目下方的空白处写入你的代码。

## 验证答案

补全所有 check 块后，先确认 plan 不报错：

```bash
terraform plan
```

如果 plan 报错，检查你的 check 块语法是否正确。注意：check 块的断言失败只会产生**警告**——如果你看到的是错误（Error），说明你的代码有语法问题。

然后用 terraform test 运行自动化测试：

```bash
terraform test
```

如果所有 check 块都正确，你会看到：

```
check_test.tftest.hcl... in progress
  run "test_bucket_managed_tag_check"... pass
  run "test_queue_retention_check"... pass
  run "test_bucket_has_config_check"... pass
check_test.tftest.hcl... tearing down
check_test.tftest.hcl... pass

Success! 3 passed, 0 failed.
```

terraform test 会自动创建资源、运行断言、最后销毁——不需要手动 apply 和 destroy。

如果某道题写错了，测试会告诉你哪个断言失败。根据错误信息修正 main.tf 后重新运行 terraform test 即可。

## 提示

如果你卡住了，以下是一些提示：

- 第 1 题：check 内不需要 data 块，直接用 assert 引用资源属性即可
- 第 2 题：和第 1 题类似，直接引用 SQS 队列的 message_retention_seconds 属性
- 第 3 题：需要在 check 块内定义一个 data "aws_s3_object" 数据源，bucket 和 key 参数分别引用已创建的 S3 桶和对象

## 关键点

- check 块的语法是 `check "名称" { ... }`
- 每个 check 块必须包含至少一个 assert 块
- assert 包含 condition 和 error_message 两个参数
- check 内可以定义一个有限作用域的数据源，用 `data "类型" "名称" { ... }` 语法
- 有限作用域数据源只能在定义它的 check 块内引用

恭喜你完成了 Checks 的学习！
