# state rm：移除资源

state rm 让 Terraform "忘记"某个资源，但不会销毁远端对象。适用于资源已被其他工具接管、或不再需要 Terraform 管理的场景。

## 1. 当前状态

确认当前状态中的资源：

```
cd /root/workspace
terraform state list
```

我们将从状态中移除 azurerm_dns_zone.data。

## 2. -dry-run 预览

```
terraform state rm -dry-run azurerm_dns_zone.data
```

输出：

```
Would remove azurerm_dns_zone.data
```

## 3. 执行 state rm

```
terraform state rm azurerm_dns_zone.data
```

输出：

```
Removed azurerm_dns_zone.data
Successfully removed 1 resource instance(s).
```

验证状态：

```
terraform state list
```

azurerm_dns_zone.data 已不在列表中。

## 4. 远端对象仍然存在

虽然 Terraform 状态中已没有 data DNS Zone，但远端仍然有：

```
azlocal dns zone list --resource-group state-demo-rg
```

你应该能看到 state-demo-data.local 仍然存在。state rm 只修改状态，不影响远端。

## 5. 观察 plan 的表现

如果配置中还保留了 azurerm_dns_zone.data 的定义，Terraform 会怎样？

```
terraform plan
```

Terraform 会计划**重新创建** data DNS Zone，因为状态中没有它的记录。

## 6. 同步配置 — 移除 resource 块

用预备好的配置替换（已移除 data DNS Zone 定义）：

```
cp /root/main-step3.tf /root/workspace/main.tf
```

再次运行 plan：

```
terraform plan
```

现在应该看到 No changes，因为配置和状态都不再包含 data DNS Zone。

## 7. 如果需要重新接管？

假设你改变了主意，想让 Terraform 重新管理 data DNS Zone。可以用 import 命令：

```
# 先在配置中重新添加 resource 块
cat >> main.tf <<'EOF'

resource "azurerm_dns_zone" "data" {
  name                = "state-demo-data.local"
  resource_group_name = azurerm_resource_group.main.name
  tags = {
    Name        = "Data DNS Zone"
    Environment = "staging"
  }
}
EOF
```

然后导入（Azure 资源 ID 需要写完整路径）：

```
terraform import azurerm_dns_zone.data /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/state-demo-rg/providers/Microsoft.Network/dnszones/state-demo-data.local
```

验证：

```
terraform plan
```

应该看到 No changes（或只有微小的属性差异）。这展示了 state rm 和 import 互为逆操作的关系。
