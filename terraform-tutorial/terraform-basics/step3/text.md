# 第三步：修改配置

现在让我们修改虚拟机的实例类型，看看 Terraform 如何处理配置变更。

## 更改实例类型

用 `sed` 命令将 `main.tf` 中的实例类型从 `t2.micro` 改为 `t2.small`：

```bash
sed -i 's/instance_type = "t2.micro"/instance_type = "t2.small"/' main.tf
```

确认修改成功：

```bash
grep instance_type main.tf
```

你应该能看到 `instance_type = "t2.small"`。

## 预览变更

先用 `plan` 查看 Terraform 打算做什么：

```bash
terraform plan
```

注意输出中的 `~` 符号——它表示资源将被**就地修改**（in-place update）。Terraform 检测到 `instance_type` 从 `t2.micro` 变为 `t2.small`。

## 应用变更

```bash
terraform apply -auto-approve
```

输出应该显示：

```text
Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
```

## 用 awslocal 确认变更

```bash
awslocal ec2 describe-instances --output json
```

在 JSON 输出中确认 `InstanceType` 已经从 `t2.micro` 变为 `t2.small`。

> 💡 Terraform 会智能判断变更类型：有些变更可以就地更新，有些则需要先销毁再重建（例如更换 AMI）。使用 `plan` 可以提前了解变更的影响。
