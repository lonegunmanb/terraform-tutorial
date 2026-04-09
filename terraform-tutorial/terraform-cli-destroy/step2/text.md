# 第二步：定向销毁（-target）与变量传入

## -target：只销毁指定资源

有时你只想销毁某个特定资源，而非全部。-target 选项让你精确控制销毁范围。

先确认当前三个资源都存在：

```
cd /root/workspace
terraform state list
```

只销毁 logs 桶，保留其他资源：

```
terraform destroy -target=aws_s3_bucket.logs -auto-approve
```

观察输出：

- 只有 aws_s3_bucket.logs 行首显示 - 符号
- 汇总行：Destroy complete! Resources: 1 destroyed.
- 末尾出现 Warning: Resource targeting is in effect 和 Warning: Applied changes may be incomplete

验证结果：

```
awslocal s3 ls
terraform state list
```

S3 列表只剩 app 桶。terraform state list 显示 logs 桶的记录已移除，但 app 桶和 DynamoDB 表仍在。

同时销毁多个资源也是支持的：

```
terraform destroy -target=aws_s3_bucket.app -target=aws_dynamodb_table.sessions -auto-approve
```

验证全部资源已销毁：

```
terraform state list
```

state 列表为空。

重建所有资源：

```
terraform apply -auto-approve
```

## destroy 与 -var-file

当配置中使用变量构建资源名称时，destroy 默认使用变量的默认值来定位资源。如果你通过 -var-file 覆盖了变量来创建资源，destroy 时也需要传入相同的 -var-file。

用 prod.tfvars 创建一套"生产"资源（名称中包含 prod 而非 dev）：

```
terraform apply -var-file=prod.tfvars -auto-approve
```

查看当前 state 中的资源——注意 apply 会先销毁 dev 资源再创建 prod 资源，因为 bucket 名称变了（这是 replace 行为）：

```
awslocal s3 ls
```

现在销毁这些 prod 资源。如果不传 -var-file 会怎样？

```
terraform destroy -auto-approve
```

虽然命令成功了，但 Terraform 用的是默认变量值（dev），在本场景中 state 里记录的是实际的资源 ID，所以 destroy 仍然能找到正确的资源销毁。不过在更复杂的场景中（如使用 Terraform Cloud 或 remote state），传入正确的变量值是一个好习惯：

```
terraform apply -var-file=prod.tfvars -auto-approve
terraform destroy -var-file=prod.tfvars -auto-approve
```

重建 dev 环境以备后续使用：

```
terraform apply -auto-approve
```
