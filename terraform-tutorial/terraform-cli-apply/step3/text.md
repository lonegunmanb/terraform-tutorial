# 第三步：定向 apply（-target）与强制重建（-replace）

## -target：只对指定资源执行变更

-target 让 apply 只作用于指定资源，忽略其他资源。这在大规模配置中临时修复单个资源时非常有用。

先制造多个资源同时有变更的场景：

```
cd /root/workspace
sed -i 's/ManagedBy   = "Terraform"/ManagedBy   = "Terraform"\n    CostCenter  = "engineering"/' main.tf
terraform plan
```

Plan 显示三个资源（2 个 S3 桶 + 1 个 DynamoDB 表）都有变更。

现在只对 app 桶执行 apply：

```
terraform apply -target=aws_s3_bucket.app -auto-approve
```

汇总行只有 1 个资源发生变化：

```
Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
```

注意 apply 输出末尾出现警告：

```
Warning: Applied changes may be incomplete
```

这提醒你 state 与配置之间仍有差距——还有两个资源没有 apply。

再次运行完整 apply 以消除差距：

```
terraform apply -auto-approve
```

恢复配置：

```
sed -i '/CostCenter.*engineering/d' main.tf
terraform apply -auto-approve
```

## -replace：强制重建资源

当远端资源内部状态损坏，需要销毁重建恢复时，-replace 让你无需修改配置就能强制触发重建（替代了已废弃的 terraform taint 命令）。

先记录 logs 桶当前的创建时间：

```
awslocal s3 ls
```

记住 logs 桶那一行的日期时间。

对 logs 桶执行强制重建：

```
terraform apply -replace=aws_s3_bucket.logs -auto-approve
```

观察输出：

- aws_s3_bucket.logs 行首显示 -/+ 符号（先销毁再重建）
- app 桶和 DynamoDB 没有任何变更
- 汇总行：Apply complete! Resources: 1 added, 0 changed, 1 destroyed.

再次查看桶列表，对比 logs 桶的创建时间：

```
awslocal s3 ls
```

logs 桶的创建时间变成了刚才 apply 的时间，说明旧桶已销毁、新桶已重建。app 桶的创建时间保持不变。

## -destroy：销毁模式

-destroy 模式将所有受管资源的操作类型设置为销毁。它是 terraform destroy 的等价命令，但可以与 apply 的其他选项（如 -target）组合使用。

先预览销毁范围：

```
terraform plan -destroy
```

三个资源行首均显示 - 符号，汇总为 Plan: 0 to add, 0 to change, 3 to destroy.

只销毁 logs 桶，保留其他资源：

```
terraform apply -destroy -target=aws_s3_bucket.logs -auto-approve
```

验证只有 logs 桶被删除：

```
awslocal s3 ls
```

恢复 logs 桶：

```
terraform apply -auto-approve
awslocal s3 ls
```

确认三个桶全部存在后进入下一步。
