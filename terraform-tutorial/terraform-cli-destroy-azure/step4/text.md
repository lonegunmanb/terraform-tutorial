# 第四步：依赖顺序销毁——time_sleep 与 depends_on 实战

## 真实案例：Azure 资源就绪状态的延迟

在真实的 Azure 环境中，许多资源在 ARM 控制平面返回 `201 Created` 之后，**资源本身的运行态（provisioningState / runtime status）还没有真正进入 `Succeeded` / `Running` / `Ready`**。比如：

- Storage Account 创建完成后，账户的 blob/queue/table 端点 DNS 还需要数秒到数十秒才能解析到节点
- AKS / VM / App Service 的控制平面对象已经存在，但容器/虚拟机进程仍在初始化，无法接受流量
- Private Endpoint 创建完成后，对应的私有 IP 与 DNS 记录还需要时间在区域内同步
- Managed Identity 创建后，新 principal 需要时间在 Azure AD 中传播到所有租户副本

如果此时把上一个资源的 `id` / `endpoint` 传给下一个 API 去建立连接（如 Private Endpoint 指向 Storage Account、App Service 配置 Key Vault 引用、role assignment 引用刚创建的 managed identity），Azure 经常会返回类似下面的瞬时错误：

```
ResourceNotReady: The resource is being provisioned. Please retry the operation.
```

或者：

```
PrincipalNotFound: Principal xxxx does not exist in the directory yyyy
```

这类问题在 azurerm provider 仓库里有大量长期 issue（典型如 [#4430 — "Principal does not exist in the directory" when creating role assignment](https://github.com/hashicorp/terraform-provider-azurerm/issues/4430)）。即使 Terraform 通过资源引用建立了隐式依赖（保证"创建完成才引用"），Azure 内部的最终一致性仍然会导致首次 apply 失败、第二次才成功的情况。

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
资源状态尚未就绪的瞬时
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

1. 创建时：隐式依赖只保证"RG 创建完成后才创建子资源"，但不保证"RG 在 Azure 内部已完全就绪"。time_sleep 的 create_duration 填补了这个时间差——在真实场景中（Storage / AKS / Managed Identity 等），这段等待是避免下游 API 报"资源未就绪"错误的关键
2. 销毁时：time_sleep 通过 depends_on 建立的依赖链确保了严格的逆序销毁——先删使用方，等一会（虽然 destroy 不会真的等 create_duration），再删被使用方

这就是 depends_on 与 time_sleep 的典型组合模式：解决云服务的最终一致性问题，同时保证创建和销毁的正确顺序。

## 清理

```
cd /root/workspace
rm -rf depends-demo
```
