# 第三步：测验 — 自己编写模块

现在轮到你动手了！请根据要求创建一个模块，并使用 terraform test 验证答案。

## 查看题目

```bash
cd /root/workspace/step3
cat main.tf
```

main.tf 中已经包含了 provider 配置和题目要求（注释中）。你的任务是：

1. 在 modules/storage 目录下创建一个模块，包含三个文件：
   - variables.tf — 定义一个 string 类型的输入变量 bucket_name
   - main.tf — 创建一个 aws_s3_bucket 资源，bucket 名称使用 var.bucket_name
   - outputs.tf — 输出 bucket_id（桶的 id）和 bucket_arn（桶的 arn）

2. 在根模块的 main.tf 中添加 module 块，调用 modules/storage 模块：
   - 模块名称为 quiz（即 module "quiz"）
   - source 指向 ./modules/storage
   - 传入 bucket_name = "quiz-bucket"

## 开始作答

先创建模块目录：

```bash
mkdir -p modules/storage
```

然后自己编写 modules/storage/variables.tf、modules/storage/main.tf 和 modules/storage/outputs.tf 三个文件，以及在 main.tf 末尾添加 module 块。

::: tip 提示
如果不确定怎么写，可以回顾上一步中 modules/s3-bucket 的代码结构。
:::

## 验证答案

完成编写后，先初始化再运行测试：

```bash
terraform init
terraform test
```

如果你的模块和调用都正确，你会看到类似输出：

```
tests/module_test.tftest.hcl... in progress
  run "module_creates_bucket"... pass
tests/module_test.tftest.hcl... tearing down
tests/module_test.tftest.hcl... pass

Success! 1 passed, 0 failed.
```

如果测试失败，根据错误信息检查：
- 是否创建了 modules/storage 目录及三个 .tf 文件？
- 模块的输出名称是否为 bucket_id 和 bucket_arn？
- module 块的名称是否为 quiz？
- bucket_name 参数是否传入了 "quiz-bucket"？

修改后重新运行 terraform test 直到通过。

## 查看测试文件（可选）

好奇测试怎么写的？查看测试文件：

```bash
cat tests/module_test.tftest.hcl
```

terraform test 使用 .tftest.hcl 文件定义测试用例。每个 run 块代表一个测试，assert 块定义断言条件。这里使用 command = plan（只做计划不实际创建）来验证模块输出是否符合预期。
