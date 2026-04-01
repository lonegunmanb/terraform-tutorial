# 第三步：删除资源——状态文件的必要性

这个实验将回答一个关键问题：**为什么 Terraform 必须有状态文件？**

想象一下：你从代码中删除了一个资源定义。代码里再也看不到这个资源了。那么 Terraform 怎么知道有一个真实的资源需要被销毁？

答案就是**状态文件**。

## 确认当前状态

先查看目前 Terraform 管理了哪些资源：

```bash
cd /root/workspace
terraform state list
```

你应该能看到 `aws_s3_bucket.data`、`aws_s3_bucket.logs` 和 `aws_dynamodb_table.locks`。

用 `awslocal` 确认 DynamoDB 表确实存在于真实环境中：

```bash
awslocal dynamodb list-tables
```

## 从代码中删除资源

现在，从 `main.tf` 中删除 DynamoDB 表的资源定义和对应的 output：

```bash
sed -i '/resource "aws_dynamodb_table" "locks"/,/^}/d' main.tf
sed -i '/output "lock_table"/,/^}/d' main.tf
```

确认代码中已经没有 DynamoDB 表的资源定义了：

```bash
grep "aws_dynamodb_table" main.tf
```

应该没有任何输出——`resource` 和 `output` 块都已被删除，Terraform 代码中不再声明这个资源。

## Terraform 如何知道要销毁？

运行 `plan` 看看 Terraform 会怎么做：

```bash
terraform plan
```

Terraform 生成了一个**销毁**计划（标记为 `-`），要删除 `aws_dynamodb_table.locks`。

思考一下这里发生了什么：代码中已经没有任何关于这个 DynamoDB 表的信息了。Terraform 之所以知道要销毁它，**完全是因为状态文件中还记录着这个资源**。Terraform 对比了代码和状态文件，发现状态文件中有一个资源在代码中找不到对应的定义，于是得出结论：这个资源应该被销毁。

## 执行销毁

```bash
terraform apply -auto-approve
```

验证资源已被删除：

```bash
awslocal dynamodb list-tables
```

`terraform-locks` 表已经不在列表中了。

## 反过来想：如果没有状态文件会怎样？

如果 Terraform 没有状态文件，当你删除代码中的资源定义时：

- 代码里没有这个资源 → Terraform 不知道它曾经存在
- 真实环境中资源还在 → 但 Terraform 无从得知
- 结果：**资源变成了孤儿**，永远留在环境中，无人管理

这就是为什么状态文件是 Terraform 架构中**不可或缺**的一部分。它不仅是记忆，更是 Terraform 判断"什么该创建、什么该修改、什么该销毁"的关键依据。

> 💡 AWS CloudFormation 和 Azure ARM 模板不需要外部状态文件，是因为它们与平台紧密耦合，平台本身就知道之前部署了什么。但 Terraform 支持任意平台，必须自己维护这份记录。

✅ 你已经通过实际操作理解了状态文件存在的根本原因。
