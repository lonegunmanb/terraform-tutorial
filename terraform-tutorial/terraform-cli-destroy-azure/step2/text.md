# 第二步：定向销毁（-target）与变量传入

## -target：只销毁指定资源

有时你只想销毁某个特定资源，而非全部。-target 选项让你精确控制销毁范围。

先确认当前四个资源都存在：

```
cd /root/workspace
terraform state list
```

只销毁 logs Subnet，保留其他资源：

```
terraform destroy -target=azurerm_subnet.logs -auto-approve
```

观察输出：

- 只有 azurerm_subnet.logs 行首显示 - 符号
- 汇总行：Destroy complete! Resources: 1 destroyed.
- 末尾出现 Warning: Resource targeting is in effect 和 Warning: Applied changes may be incomplete

验证结果：

```
azlocal network vnet subnet list --resource-group myapp-dev-rg-lab --vnet-name myapp-dev-vnet-lab
terraform state list
```

Subnet 列表只剩 app 一个。terraform state list 显示 logs 的记录已移除，但 app Subnet、Virtual Network 与 Resource Group 仍在。

同时销毁多个资源也是支持的（注意：销毁 VNet 会连带销毁其下属的 app Subnet，因为 Subnet 依赖 VNet）：

```
terraform destroy -target=azurerm_subnet.app -target=azurerm_virtual_network.net -auto-approve
```

验证只剩 Resource Group：

```
terraform state list
```

state 中只剩 azurerm_resource_group.main。

重建所有资源：

```
terraform apply -auto-approve
```

## destroy 与 -var-file

当配置中使用变量构建资源名称时，destroy 默认使用变量的默认值来定位资源。如果你通过 -var-file 覆盖了变量来创建资源，destroy 时也需要传入相同的 -var-file。

用 prod.tfvars 创建一套"生产"资源（名称中包含 prod 而非 dev）：

```
terraform apply -var-file=prod.tfvars -auto-approve
```

查看当前 state 中的资源——注意 apply 会先销毁 dev 资源再创建 prod 资源，因为名称变了（这是 replace 行为）：

```
azlocal group list
```

现在销毁这些 prod 资源。如果不传 -var-file 会怎样？

```
terraform destroy -auto-approve
```

虽然命令成功了，但 Terraform 用的是默认变量值（dev），在本场景中 state 里记录的是实际的资源 ID，所以 destroy 仍然能找到正确的资源销毁。不过在更复杂的场景中（如使用 Terraform Cloud 或 remote state），传入正确的变量值是一个好习惯：

```
terraform apply -var-file=prod.tfvars -auto-approve
terraform destroy -var-file=prod.tfvars -auto-approve
```

重建 dev 环境以备后续使用：

```
terraform apply -auto-approve
```
