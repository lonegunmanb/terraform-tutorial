# 第一步：创建资源与交互确认

## 首次 apply

进入工作目录，查看初始状态：

```
cd /root/workspace
ls -la
```

可以看到 main.tf、docker-compose.yml 和 .terraform 目录（providers 已下载），但没有 terraform.tfstate——资源尚未创建。

运行 terraform apply：

```
terraform apply
```

Terraform 会先输出完整计划，三个资源行首均显示 + 符号（将被创建），末尾显示：

```
Plan: 3 to add, 0 to change, 0 to destroy.
```

然后出现确认提示：

```
Do you want to perform these actions?
  Only 'yes' will be accepted to approve.

  Enter a value:
```

输入 yes 并回车，Terraform 开始创建资源并实时打印进度：

```
aws_dynamodb_table.sessions: Creating...
aws_s3_bucket.app: Creating...
aws_s3_bucket.logs: Creating...
aws_s3_bucket.app: Creation complete after 1s
aws_dynamodb_table.sessions: Creation complete after 2s
aws_s3_bucket.logs: Creation complete after 1s

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

apply 完成后还会打印所有输出值（Outputs）。

验证资源已创建：

```
awslocal s3 ls
awslocal dynamodb list-tables
```

此时工作目录中多出了 terraform.tfstate 文件，里面记录着所有受管资源的状态：

```
ls -lh terraform.tfstate
```

## 变更后的 apply 与 -auto-approve

修改 local.common_tags，添加一个新标签（三个资源共用这个 locals，所以全部会被标记为变更）：

```
sed -i 's/ManagedBy   = "Terraform"/ManagedBy   = "Terraform"\n    Owner       = "platform-team"/' main.tf
```

这次使用 -auto-approve 跳过确认提示，直接执行：

```
terraform apply -auto-approve
```

与首次 apply 对比，注意两处差异：

- 操作类型从 Creating... 变为 Modifying...
- 汇总行：Apply complete! Resources: 0 added, 3 changed, 0 destroyed.

再次运行，验证 apply 的幂等性：

```
terraform apply -auto-approve
```

配置与远端完全一致时，apply 输出：

```
No changes. Your infrastructure matches the configuration.
```

## 恢复配置

移除刚才添加的标签，恢复干净状态：

```
sed -i '/Owner.*platform-team/d' main.tf
terraform apply -auto-approve
```

确认汇总行显示 0 added, 3 changed（还原了标签），然后再次运行确认 No changes。
