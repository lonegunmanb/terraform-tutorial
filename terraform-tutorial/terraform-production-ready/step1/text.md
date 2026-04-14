# 第一步：观察大模块——症结在哪里

## 看看我们要重构的代码

进入第一个工作目录，查看这个"大模块"：

```bash
cd /root/workspace/step1
cat main.tf
```

你会看到这个文件里塞进了所有东西：S3 存储桶、SQS 队列、DynamoDB 表、IAM 策略，以及它们的配置项，全部挤在同一个文件里。

## 统计一下规模

```bash
wc -l main.tf
terraform fmt -check main.tf
```

这个文件只有约 100 行——在实际项目中，一个未经治理的 Terraform 模块很容易膨胀到 3000 行以上。

## 运行一下，看看有什么

```bash
terraform init
terraform plan
```

观察 `plan` 的输出。你能在几秒内准确告诉我这里有几类资源、每类各有几个吗？

```bash
terraform apply -auto-approve
```

## 验证已创建的资源

```bash
awslocal s3 ls
awslocal sqs list-queues
awslocal dynamodb list-tables
awslocal iam list-policies --scope Local
```

资源都创建成功了。现在想象一个场景：**你需要把 SQS 死信队列的最大接收次数从 5 改成 3**。

打开 main.tf，找到这一行——你需要在 100 行里先找到它。在一个真实项目的 3000 行文件里，这会花多久？

如果你在修改时不小心把相邻的 DynamoDB 表也改了，`plan` 输出可能有几百行，你能及时发现吗？

## 大模块的五个问题

运行下面的命令，看看状态文件里有多少资源：

```bash
terraform state list
```

这些资源地址都是扁平的，没有任何层次结构。如果要做到最小权限（某个人只能修改 SQS，不能动 DynamoDB），你无法做到——所有资源在同一个模块里，要么全有权限，要么全没有。

| 问题 | 表现 |
|------|------|
| 慢 | `plan` 需要查询所有资源的真实状态 |
| 不安全 | 无法按资源类型给最小权限 |
| 高风险 | 改 A 时容易误中 B |
| 难理解 | 没有人能看完 3000 行后还记得开头 |
| 难测试 | 要测试 SQS 逻辑，必须一起 apply 所有资源 |

下一步，我们来拆解这个单体。
