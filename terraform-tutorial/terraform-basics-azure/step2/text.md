# 第二步：验证幂等性

Terraform 的一个重要特性是**幂等性**——如果基础设施已经处于期望状态，重复执行 apply 不会产生任何变更。

## 再次执行 apply

```
terraform apply -auto-approve
```

观察输出，你应该会看到：

```
No changes. Your infrastructure matches the configuration.

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
```

这说明 Terraform 检测到当前状态已经与配置文件一致，没有任何变更需要执行。

## 用 azlocal 再次确认

```
azlocal network vnet list --resource-group TerraformTutorial-rg
```

VNet 依然存在，addressPrefixes 仍然是 10.0.0.0/16——没有任何变化。

也可以查看 Terraform state，确认它已记录这两个资源：

```
terraform state list
```

应该列出：

```
azurerm_resource_group.tutorial
azurerm_virtual_network.tutorial
```

> 💡 幂等性是基础设施即代码（IaC）的核心优势之一。你可以放心地多次执行 terraform apply，Terraform 只会在需要时才进行变更。
