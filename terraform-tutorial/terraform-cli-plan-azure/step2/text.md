# 第二步：规划模式（-destroy 与 -refresh-only）

## -destroy：预览全量销毁

-destroy 模式创建一份目标为销毁所有受管资源的计划，是 terraform destroy 的预览版本：

```
cd /root/workspace
terraform plan -destroy
```

仔细阅读输出，你会看到：

- 四个资源行首均显示 - 符号
- 汇总行：Plan: 0 to add, 0 to change, 4 to destroy

这个模式让你在执行 terraform destroy 之前确认销毁范围，尤其在生产环境中非常重要。

## -refresh-only：模拟带外变更（out-of-band change）

"带外变更"是指绕过 Terraform 直接在 Azure Portal 或 CLI 修改资源（例如手动删除一个 DNS Zone）。下面模拟这个场景。

直接用 azlocal 删除 app DNS Zone（模拟有人手动删除了这个资源）：

```
azlocal dns zone delete --resource-group myapp-dev-rg-lab --name myapp-dev-app-lab.local
```

确认 zone 已删除（用 jq 只取剩余 Zone 的名字，便于看出 app 已不在列表中）：

```
azlocal dns zone list --resource-group myapp-dev-rg-lab | jq -r '.value[].name'
```

预期输出（只剩 logs zone，app zone 已消失）：

```
myapp-dev-logs-lab.local
```

现在运行普通的 terraform plan：

```
terraform plan
```

Terraform 会检测到 app DNS Zone 已经不存在，并提出重新创建它——符号为 +。这是正常的 plan 行为：将远端状态对齐到配置。

但如果这个删除是预期的，你想让 state 去掉这条记录而不是重新创建这个资源，就需要 -refresh-only：

```
terraform plan -refresh-only
```

输出会显示：

- azurerm_dns_zone.app 将从 state 中移除（以 - 标记，但注意这只是 state 变更，不是资源操作）
- 汇总：这是一个 state 更新计划，不会新建或销毁任何实际资源

如果此时 apply 这份计划，结果只有一个：Terraform 的 state 文件会更新，移除 app DNS Zone 的记录，而远端什么都不会变。

## 恢复环境

重新创建被删除的 DNS Zone，以便后续步骤使用：

```
terraform apply -auto-approve
azlocal dns zone list --resource-group myapp-dev-rg-lab | jq -r '.value[].name'
```

确认两个 DNS Zone、Virtual Network 和 Resource Group 都已就绪。
