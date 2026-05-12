# 第四步：依赖顺序销毁——time_sleep 与 depends_on 实战

## 真实案例：Azure 控制平面的最终一致性

在真实的 Azure 环境中，Resource Group / Role Assignment / Managed Identity 等控制平面对象都属于 ARM 全局服务，创建后需要数秒到数十秒才能在所有区域 / 服务端点完全生效（最终一致性）。如果另一个资源在前者未传播完成时就引用它，Azure API 会返回类似下面的瞬时错误：

```
PrincipalNotFound: Principal xxxx does not exist in the directory yyyy
```

或者：

```
ResourceGroupNotFound: Resource group 'foo' could not be found
```

这是一个长期存在的问题（参考 https://github.com/hashicorp/terraform-provider-azurerm/issues/4430 ——"Principal does not exist in the directory" when creating role assignment）。即使 Terraform 通过资源引用建立了隐式依赖，Azure AD / ARM 控制平面的最终一致性仍然会导致首次 apply 失败、第二次才成功的情况。

解决方案是使用 time_sleep 资源强制等待传播完成。这不仅保证了创建时的正确顺序，也确保了销毁时先删除引用方（DNS Zone、VNet），再删除被引用方（Resource Group）。

## 查看配置

进入预先准备好的 depends-demo 目录：

```
cd /root/workspace/depends-demo
cat main.tf
```

配置中有 4 个资源，依赖链如下：

```
azurerm_resource_group.app
       │
       ▼
time_sleep.azure_propagation (等待 10 秒)
       │
       ├──→ azurerm_dns_zone.data
       └──→ azurerm_virtual_network.net
```

关键设计：

- time_sleep 通过 depends_on 显式依赖 Resource Group
- time_sleep.triggers 中存储 rg_name 和 location，供下游资源引用
- DNS Zone 与 VNet 通过 time_sleep.triggers["rg_name"] 获取 RG 名（而非直接引用 azurerm_resource_group.app.name）

这样 Terraform 的依赖图就包含了 time_sleep 节点，强制在 RG 创建后等待 10 秒再创建子资源。

## 观察创建顺序

```
terraform apply -auto-approve
```

仔细观察输出中的时间线：

1. azurerm_resource_group.app 最先创建
2. time_sleep.azure_propagation 开始等待——注意 Terraform 打印 "Still creating..." 每隔几秒一次，直到 10 秒过去
3. azurerm_dns_zone.data 与 azurerm_virtual_network.net 并行创建（都依赖 time_sleep，互不依赖）

如果跳过 time_sleep 直接引用 azurerm_resource_group.app.name，Terraform 会在 RG 创建完成后立刻创建子资源——在真实 Azure 上偶尔触发 "ResourceGroupNotFound" 错误。

## 查看依赖图

```
terraform graph | grep '\->' | grep -v provider | grep -v '\[root\]'
```

注意 time_sleep 节点同时作为 RG 和下游资源之间的桥梁。

## 观察销毁顺序

```
terraform destroy -auto-approve
```

观察 Destroying... 行的顺序：

1. azurerm_dns_zone.data 与 azurerm_virtual_network.net 最先销毁（叶子节点，并行）
2. time_sleep.azure_propagation 随后销毁
3. azurerm_resource_group.app 最后销毁（已无其他资源依赖它）

销毁顺序严格遵循依赖链的逆序。这保证了：

- 子资源在 Resource Group 之前被删除——如果反过来，子资源会变成"孤儿"
- 在真实 Azure 中，删除非空 Resource Group 默认会级联删除所有子资源，但顺序由 Azure 决定，无法保证；用 Terraform 显式按逆序销毁可以让你掌控全过程

## 为什么不能去掉 time_sleep

你可能会想：既然 DNS Zone / VNet 通过 azurerm_resource_group.app.name 已经有了隐式依赖，为什么还需要 time_sleep？

原因有两个：

1. 创建时：隐式依赖只保证"RG 创建完成后才创建子资源"，但不保证"RG 在 Azure 内部已传播完成"。time_sleep 的 create_duration 填补了这个时间差
2. 销毁时：time_sleep 通过 depends_on 建立的依赖链确保了严格的逆序销毁——先删使用方，等一会（虽然 destroy 不会真的等 create_duration），再删被使用方

这就是 depends_on 与 time_sleep 的典型组合模式：解决云服务的最终一致性问题，同时保证创建和销毁的正确顺序。

## 清理

```
cd /root/workspace
rm -rf depends-demo
```
