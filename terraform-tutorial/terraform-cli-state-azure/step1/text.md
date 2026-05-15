# state list / state show / state pull：读取状态

进入工作目录：

```
cd /root/workspace
```

## 1. state list — 列出所有资源

查看状态中管理的所有资源：

```
terraform state list
```

输出会列出 5 个资源地址：

```
azurerm_dns_zone.app
azurerm_dns_zone.data
azurerm_dns_zone.logs
azurerm_resource_group.main
azurerm_virtual_network.net
```

### 用 grep 过滤

只查看 DNS Zone：

```
terraform state list | grep azurerm_dns_zone
```

只会显示 3 个 DNS Zone，Resource Group 与 Virtual Network 被过滤掉。

### 按 ID 过滤

如果你知道远端资源的 ID，但不确定它在 Terraform 中叫什么名字：

```
terraform state list -id=/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/state-demo-rg/providers/Microsoft.Network/dnszones/state-demo-logs.local
```

输出只会显示匹配的资源地址。

::: tip
Azure 资源 ID 是包含 subscription / resourceGroup / 资源类型 / 名称的完整路径，比 AWS 的 ARN 更长。可以用 terraform state show 先查到资源的 id 字段，再用 -id 过滤。
:::

## 2. state show — 查看资源详情

查看 app DNS Zone 的完整属性：

```
terraform state show azurerm_dns_zone.app
```

输出包含该资源在状态中记录的所有属性（name、resource_group_name、id、tags、name_servers 等）。这些信息直接从状态文件读取，不会查询远端。

再看一下 Virtual Network：

```
terraform state show azurerm_virtual_network.net
```

对比两个资源的输出，注意不同资源类型记录的属性完全不同。

## 3. state pull — 下载原始状态 JSON

将完整的状态文件以 JSON 格式输出：

```
terraform state pull | python3 -m json.tool | head -30
```

输出是标准的 Terraform 状态 JSON，包含 version、serial、terraform_version 等元数据。

### 提取关键信息

用 python3 提取状态的元数据：

```
terraform state pull | python3 -c "
import sys, json
state = json.load(sys.stdin)
print('State version:', state.get('version'))
print('Serial:', state.get('serial'))
print('Terraform version:', state.get('terraform_version'))
print('Resource count:', len(state.get('resources', [])))
"
```

### 列出所有资源类型和名称

```
terraform state pull | python3 -c "
import sys, json
state = json.load(sys.stdin)
for r in state.get('resources', []):
    print(f\"{r['type']}.{r['name']}\")
"
```

这与 state list 的输出一致，但通过 JSON 你可以做更复杂的分析。

### 备份状态

在做危险操作前，先备份当前状态：

```
terraform state pull > /tmp/state-backup.json
```

后续步骤如果出现问题，可以用这个备份恢复。
