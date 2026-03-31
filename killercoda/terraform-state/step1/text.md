# 第一步：查看状态

列出所有被 Terraform 管理的资源：

```bash
cd /root/workspace
terraform state list
```

你应该看到三个资源地址：
- `aws_s3_bucket.data`
- `aws_s3_bucket.logs`
- `aws_dynamodb_table.locks`

查看某个资源的详细属性：

```bash
terraform state show aws_s3_bucket.data
```

注意输出中的 `id`、`arn`、`tags` 等字段——这些都是 Terraform 从真实环境读回来的。

再试一个：

```bash
terraform state show aws_dynamodb_table.locks
```

✅ 你已经学会了 `state list` 和 `state show` 两个最常用的状态查看命令。
