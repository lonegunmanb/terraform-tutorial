# state rm：移除资源

state rm 让 Terraform "忘记"某个资源，但不会销毁远端对象。适用于资源已被其他工具接管、或不再需要 Terraform 管理的场景。

## 1. 当前状态

确认当前状态中的资源：

```
cd /root/workspace
terraform state list
```

我们将从状态中移除 azurerm_subnet.data。

## 2. -dry-run 预览

```
terraform state rm -dry-run azurerm_subnet.data
```

输出：

```
Would remove azurerm_subnet.data
```

## 3. 执行 state rm

```
terraform state rm azurerm_subnet.data
```

输出：

```
Removed azurerm_subnet.data
Successfully removed 1 resource instance(s).
```

验证状态：

```
terraform state list
```

azurerm_subnet.data 已不在列表中。

## 4. 远端对象仍然存在

虽然 Terraform 状态中已没有 data subnet，但远端仍然有：

```
azlocal network vnet subnet list --resource-group state-demo-rg --vnet-name state-demo-vnet
```

你应该能看到 state-demo-data 仍然存在。state rm 只修改状态，不影响远端。

## 5. 观察 plan 的表现

如果配置中还保留了 azurerm_subnet.data 的定义，Terraform 会怎样？

```
terraform plan
```

Terraform 会计划**重新创建** data subnet，因为状态中没有它的记录。

## 6. 同步配置 — 移除 resource 块

用预备好的配置替换（已移除 data subnet 定义）：

```
cp /root/main-step3.tf /root/workspace/main.tf
```

再次运行 plan：

```
terraform plan
```

现在应该看到 No changes，因为配置和状态都不再包含 data subnet。

## 7. 如果需要重新接管？

假设你改变了主意，想让 Terraform 重新管理 data subnet。可以用 import 命令：

```
# 先在配置中重新添加 resource 块
cat >> main.tf <<'EOF'

resource "azurerm_subnet" "data" {
  name                 = "state-demo-data"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.net.name
  address_prefixes     = ["10.0.3.0/24"]
}
EOF
```

然后导入（Azure 资源 ID 需要写完整路径）：

```
terraform import azurerm_subnet.data /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/state-demo-rg/providers/Microsoft.Network/virtualNetworks/state-demo-vnet/subnets/state-demo-data
```

验证：

```
terraform plan
```

应该看到 No changes（或只有微小的属性差异）。这展示了 state rm 和 import 互为逆操作的关系。
