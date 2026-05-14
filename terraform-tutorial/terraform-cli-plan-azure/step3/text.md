# 第三步：-out 保存计划、-target 定向规划、-replace 强制重建

## -out：保存计划文件

把计划保存到文件，确保 apply 时执行的是经过审查的计划：

```
cd /root/workspace
terraform plan -out=tfplan
```

计划文件是不透明的二进制格式，用 terraform show 以人类可读格式查看内容：

```
terraform show tfplan
```

尝试用 cat 查看会是乱码：

```
cat tfplan | head -5
```

在真实的 CI/CD 工作流中，plan 和 apply 是两条独立的流水线任务：

1. terraform plan -out=tfplan（PR 评审阶段，计划文件作为制品上传）
2. terraform apply tfplan（合并并审批后，下载制品执行）

这样无论 apply 前配置发生了什么变化，执行的都是审批过的内容。

删除计划文件，恢复干净状态：

```
rm tfplan
```

## -target：只规划指定资源

向 app DNS Zone 和 logs DNS Zone 的配置中同时添加一个新标签，制造两个待变更的资源（注意 RG 和 vnet 也共用 locals，所以会一并变更）：

```
sed -i 's/ManagedBy   = "Terraform"/ManagedBy   = "Terraform"\n    CostCenter  = "engineering"/' main.tf
terraform plan
```

四个资源都会出现在 plan 中。现在用 -target 只对 app DNS Zone 做计划，忽略其他资源：

```
terraform plan -target=azurerm_dns_zone.app
```

对比两次输出的汇总行：

- 完整 plan：Plan: 0 to add, 4 to change, 0 to destroy
- 定向 plan：只覆盖 app DNS Zone 及其依赖（azurerm_resource_group.main）

注意输出末尾 Terraform 给出的警告：

```
Warning: Resource targeting is in effect
```

这提醒你 -target 是特殊手段，不应在常规工作流中使用。

恢复配置：

```
sed -i '/CostCenter.*engineering/d' main.tf
terraform plan
```

确认显示 No changes。

## -replace：强制重建指定资源

有时某个远端资源虽然存在，但内部状态损坏，需要通过重建来修复。-replace 让你无需修改配置就能强制触发 replace 行为：

```
terraform plan -replace=azurerm_dns_zone.logs
```

观察 azurerm_dns_zone.logs 行首显示 -/+ 符号（先销毁再重建），而 app DNS Zone、Resource Group 和 Virtual Network 没有任何变更。

汇总行：

```
Plan: 1 to add, 0 to change, 1 to destroy.
```

同时替换多个资源：

```
terraform plan -replace=azurerm_dns_zone.app -replace=azurerm_dns_zone.logs
```

汇总变为：

```
Plan: 2 to add, 0 to change, 2 to destroy.
```

-replace 替代了老版本的 terraform taint 命令——效果一样，但直接在 plan/apply 时指定，不需要提前污染 state。
