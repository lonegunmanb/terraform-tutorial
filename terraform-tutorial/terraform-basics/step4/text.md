# 第四步：销毁资源

当你不再需要基础设施时，Terraform 可以帮你清理所有资源。

## 执行 destroy

```bash
terraform destroy -auto-approve
```

Terraform 会删除所有它管理的资源。输出应该显示：

```text
Destroy complete! Resources: 1 destroyed.
```

## 用 awslocal 确认资源已清除

```bash
awslocal ec2 describe-instances --output json
```

你应该看到实例的状态变为 `terminated`，或者 `Reservations` 为空——说明资源已经被完全清除。

你也可以用过滤器只查看运行中的实例，确认没有残留：

```bash
awslocal ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --output json
```

`Reservations` 应该为空数组 `[]`，说明所有 EC2 实例均已被销毁。

> 💡 `terraform destroy` 是 `terraform apply -destroy` 的快捷方式。在生产环境中，建议先执行 `terraform plan -destroy` 预览将要销毁的资源，确认无误后再执行销毁。
