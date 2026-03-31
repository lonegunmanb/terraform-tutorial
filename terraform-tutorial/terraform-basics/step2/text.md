# 第二步：验证幂等性

Terraform 的一个重要特性是**幂等性**——如果基础设施已经处于期望状态，重复执行 `apply` 不会产生任何变更。

## 再次执行 apply

```bash
terraform apply -auto-approve
```

观察输出，你应该会看到：

```text
No changes. Your infrastructure matches the configuration.

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
```

这说明 Terraform 检测到当前状态已经与配置文件一致，没有任何变更需要执行。

## 用 awslocal 再次确认

```bash
awslocal ec2 describe-instances --output json
```

实例依然存在，类型仍然是 `t2.micro`，状态仍然是 `running`——没有任何变化。

> 💡 幂等性是基础设施即代码（IaC）的核心优势之一。你可以放心地多次执行 `terraform apply`，Terraform 只会在需要时才进行变更。
