# 第一步：预览销毁与交互确认

## 确认当前资源

进入工作目录，确认三个资源已存在：

```
cd /root/workspace
awslocal s3 ls
awslocal dynamodb list-tables
```

查看 Terraform state 中的受管资源列表：

```
terraform state list
```

应显示三个资源：aws_s3_bucket.app、aws_s3_bucket.logs、aws_dynamodb_table.sessions。

## 预览销毁：plan -destroy

在真正执行销毁之前，先用 plan -destroy 预览销毁范围：

```
terraform plan -destroy
```

观察输出：

- 三个资源行首均显示 - 符号（将被销毁）
- 每个属性行前也是 -，值末尾标记 -> null（将被清除）
- 汇总行：Plan: 0 to add, 0 to change, 3 to destroy

这份计划是"推测性的"——不会做任何实际变更，仅供审查。

## 执行销毁：交互确认

现在执行真正的销毁。terraform destroy 会先输出与 plan -destroy 相同的计划，然后等待确认：

```
terraform destroy
```

注意确认提示的措辞与 terraform apply 不同：

```
Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value:
```

输入 yes 并回车。Terraform 按依赖关系逆序销毁资源，实时打印进度：

```
aws_s3_bucket.app: Destroying... [id=myapp-dev-app-lab]
aws_s3_bucket.logs: Destroying... [id=myapp-dev-logs-lab]
aws_dynamodb_table.sessions: Destroying... [id=myapp-dev-sessions]
```

全部完成后显示：

```
Destroy complete! Resources: 3 destroyed.
```

## 验证资源已全部删除

```
awslocal s3 ls
awslocal dynamodb list-tables
terraform state list
```

S3 桶列表为空，DynamoDB 表列表为空，terraform state list 无输出——所有资源已销毁，state 已清空。

## 重建资源

后续步骤需要用到这些资源，重新创建：

```
terraform apply -auto-approve
awslocal s3 ls
```

确认两个 S3 桶存在后进入下一步。
