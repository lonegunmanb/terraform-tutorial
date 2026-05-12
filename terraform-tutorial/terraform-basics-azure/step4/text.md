# 第四步：销毁资源

当你不再需要基础设施时，Terraform 可以帮你清理所有资源。

## 执行 destroy

```
terraform destroy -auto-approve
```

Terraform 会删除所有它管理的资源，先删除 VNet，再删除 Resource Group（按依赖关系倒序销毁）。输出应该显示：

```
Destroy complete! Resources: 2 destroyed.
```

## 用 azlocal 确认资源已清除

```
azlocal network vnet list --resource-group TerraformTutorial-rg
```

由于 Resource Group 已被删除，命令可能返回空列表或报错（找不到资源组）——这都说明 VNet 已被清除。

再确认 Resource Group 也已不存在：

```
azlocal group list
```

输出中应该不再包含 TerraformTutorial-rg。

> 💡 terraform destroy 是 terraform apply -destroy 的快捷方式。在生产环境中，建议先执行 terraform plan -destroy 预览将要销毁的资源，确认无误后再执行销毁。
