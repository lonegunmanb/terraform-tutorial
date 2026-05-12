# 第三步：修改配置

现在让我们修改 Virtual Network 的地址空间，看看 Terraform 如何处理配置变更。

## 更改 address_space

用 sed 命令将 main.tf 中 VNet 的地址空间从 10.0.0.0/16 改为 10.1.0.0/16：

```
sed -i 's|address_space       = \["10.0.0.0/16"\]|address_space       = ["10.1.0.0/16"]|' main.tf
```

确认修改成功：

```
grep address_space main.tf
```

你应该能看到 address_space = ["10.1.0.0/16"]。

## 预览变更

先用 plan 查看 Terraform 打算做什么：

```
terraform plan
```

注意输出中的 ~ 符号——它表示资源将被**就地修改**（in-place update）。Terraform 检测到 VNet 的 address_space 从 10.0.0.0/16 变为 10.1.0.0/16，但 VNet 本身不会被删除重建。

## 应用变更

```
terraform apply -auto-approve
```

输出应该显示：

```
Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
```

## 用 azlocal 确认变更

```
azlocal network vnet list --resource-group TerraformTutorial-rg
```

在输出中确认 addressPrefixes 已经从 10.0.0.0/16 变为 10.1.0.0/16。

> 💡 Terraform 会智能判断变更类型：有些变更可以就地更新（如 VNet 的地址空间、资源标签），有些则需要先销毁再重建（如修改资源名称、location）。使用 plan 可以提前了解变更的影响。
