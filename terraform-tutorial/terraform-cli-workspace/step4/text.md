# 第四步：清理 workspace——销毁资源与删除 workspace

## 尝试直接删除有资源的 workspace

先尝试删除 staging workspace（当前在 staging）：

```
cd /root/workspace
terraform workspace select default
terraform workspace delete staging
```

Terraform 报错拒绝删除——staging workspace 仍在追踪资源：

```
Workspace "staging" is not empty.
```

这是 Terraform 的安全保护机制，防止你意外丢失对资源的管理。

## 正确流程：先销毁资源再删除 workspace

切到 staging workspace，先销毁所有资源：

```
terraform workspace select staging
terraform destroy -auto-approve
```

确认资源已销毁：

```
awslocal s3 ls | grep staging
```

没有输出说明 staging 的 S3 桶已经不存在了。

切回 default，然后删除 staging workspace：

```
terraform workspace select default
terraform workspace delete staging
```

输出：

```
Deleted workspace "staging".
```

确认 workspace 已被删除：

```
terraform workspace list
```

只剩 default 和 dev 两个 workspace。

## 清理 dev workspace

用同样的流程清理 dev workspace：

```
terraform workspace select dev
terraform destroy -auto-approve
terraform workspace select default
terraform workspace delete dev
```

确认只剩 default workspace：

```
terraform workspace list
```

## -force 强制删除（了解即可）

如果确实需要删除还有资源的 workspace，可以使用 -force 参数：

```
terraform workspace new temp-test
terraform apply -auto-approve
terraform workspace select default
terraform workspace delete -force temp-test
```

Terraform 会警告但执行删除。此时 temp-test workspace 的资源仍然物理存在于 LocalStack 中，但 Terraform 已经不再管理它们了——这些资源变成了"悬空资源"。

验证资源仍然存在但不在任何 state 中：

```
awslocal s3 ls | grep temp-test
terraform show | grep temp-test
```

第一行有输出（桶还在），第二行没有输出（state 中没有记录）。在生产环境中，这种悬空资源需要手动清理，因此 -force 应谨慎使用。

手动清理悬空资源：

```
awslocal s3 rb s3://myapp-temp-test-data --force
awslocal dynamodb delete-table --table-name myapp-temp-test-sessions
```

## 最终清理

销毁 default workspace 中的资源：

```
terraform workspace select default
terraform destroy -auto-approve
```

确认所有资源都已清理：

```
awslocal s3 ls
awslocal dynamodb list-tables
```

确认 Destroy complete 后进入完成页。
