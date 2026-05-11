# 第三步：定向 apply（-target）与强制重建（-replace）

## -target：只对指定资源执行变更

-target 让 apply 只作用于指定资源，忽略其他资源。这在大规模配置中临时修复单个资源时非常有用。

先制造多个资源同时有变更的场景：

```
cd /root/workspace
sed -i 's/ManagedBy   = "Terraform"/ManagedBy   = "Terraform"\n    CostCenter  = "engineering"/' main.tf
terraform plan
```

Plan 显示四个资源都有变更。

现在只对 app DNS Zone 执行 apply：

```
terraform apply -target=azurerm_dns_zone.app -auto-approve
```

汇总行只有 1 个资源发生变化：

```
Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
```

注意 apply 输出末尾出现警告：

```
Warning: Applied changes may be incomplete
```

这提醒你 state 与配置之间仍有差距——还有三个资源没有 apply。

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

先记录 logs DNS Zone 当前的资源 ID：

```
terraform state show azurerm_dns_zone.logs | grep -E '^\s*id\s*='
```

记住这一行的值。

对 logs DNS Zone 执行强制重建：

```
terraform apply -replace=azurerm_dns_zone.logs -auto-approve
```

观察输出：

- azurerm_dns_zone.logs 行首显示 -/+ 符号（先销毁再重建）
- app DNS Zone、虚拟网络与 Resource Group 没有任何变更
- 汇总行：Apply complete! Resources: 1 added, 0 changed, 1 destroyed.

再次查看 logs DNS Zone 的 ID：

```
terraform state show azurerm_dns_zone.logs | grep -E '^\s*id\s*='
```

ID 已发生变化（重建后是新的资源），其他资源不受影响。

## -destroy：销毁模式

-destroy 模式将所有受管资源的操作类型设置为销毁。它是 terraform destroy 的等价命令，但可以与 apply 的其他选项（如 -target）组合使用。

先预览销毁范围：

```
terraform plan -destroy
```

四个资源行首均显示 - 符号，汇总为 Plan: 0 to add, 0 to change, 4 to destroy.

只销毁 logs DNS Zone，保留其他资源：

```
terraform apply -destroy -target=azurerm_dns_zone.logs -auto-approve
```

验证 state 中只剩三个资源：

```
terraform state list
```

恢复 logs DNS Zone：

```
terraform apply -auto-approve
terraform state list
```

确认四个资源全部存在后进入下一步。
