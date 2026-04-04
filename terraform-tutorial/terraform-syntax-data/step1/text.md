# 第一步：数据源基础 — 查询环境信息

在这一步中，你将使用最简单的数据源——查询当前 AWS 账号和区域信息，然后在资源中引用这些信息。

## 查看代码

```bash
cd /root/workspace/step1
cat main.tf
```

观察代码中的关键点：

- **data 块语法** — `data "类型" "名称" { ... }`，与 resource 块结构一致，但关键字是 `data`
- **空的 data 块** — `data "aws_caller_identity" "current" {}` 不需要查询参数，它自动返回当前调用者信息
- **引用语法** — `data.aws_caller_identity.current.account_id`，以 `data.` 开头
- **data + resource 协作** — 桶名使用 `data` 查询到的账号 ID 和区域拼接，确保全局唯一

## 执行 Plan

```bash
terraform plan
```

观察输出中的关键信息：

- 数据源在 plan 阶段就被读取了（因为它们不依赖任何未创建的资源）
- 桶名已经被计算出来，包含具体的账号 ID 和区域
- `+` 号前面是 `resource`（要创建的资源），数据源只是提供信息

## 执行 Apply

```bash
terraform apply -auto-approve
```

观察输出值：
- `account_id` — LocalStack 返回的模拟账号 ID
- `caller_arn` — 当前调用者的 ARN
- `region` — 应该是 `us-east-1`（与 provider 配置一致）
- `bucket_name` — 包含账号 ID 和区域的唯一桶名

## 验证

```bash
# 查看 S3 桶
awslocal s3 ls

# 查看元数据文件内容
awslocal s3 cp s3://$(terraform output -raw bucket_name)/metadata.json - | python3 -m json.tool
```

元数据文件中记录了数据源查询到的所有信息——这些信息由 `data` 提供，在 `resource` 中使用。

## 查看状态文件中的数据源

```bash
terraform state list
```

你会看到状态文件中同时包含 `data.` 和 `resource.` 两类对象。数据源的查询结果也会缓存在状态文件中。

```bash
terraform state show data.aws_caller_identity.current
terraform state show data.aws_region.current
```

## 关键点

- data 块的语法与 resource 块相似，关键字不同
- 引用数据源用 `data.<类型>.<名称>.<属性>`
- 数据源是只读的——不会创建、修改或删除任何资源
- 查询参数已知时，数据源在 plan 阶段就会被读取
- 数据源的查询结果缓存在状态文件中

## 清理

```bash
terraform destroy -auto-approve
```

完成后继续下一步。
