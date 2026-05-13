# 第二步：导入到 for_each 资源

## 查看预置的 for_each 配置

/root 下已预置了 foreach.tf 文件，查看其内容：

```
cat /root/foreach.tf
```

配置使用 for_each 为 dev 和 staging 两个环境各创建一个 Resource Group。环境中已通过 miniblue ARM API 预创建了 app-dev-rg 和 app-staging-rg 这两个资源组。

将配置复制到工作目录：

```
cp /root/foreach.tf .
```

## 尝试不导入直接 plan

先看看如果不导入会怎样：

```
terraform plan
```

plan 显示要创建两个新资源组——Terraform 不知道这些资源组已经存在。如果直接 apply，会因为名称冲突而报错。

## 用命令行导入 for_each 资源

for_each 资源的地址需要带上 key，azurerm 资源仍然使用完整的 Azure Resource ID 作为 import 的 ID：

```
terraform import 'azurerm_resource_group.per_env["dev"]' /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/app-dev-rg
terraform import 'azurerm_resource_group.per_env["staging"]' /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/app-staging-rg
```

注意地址中的引号——使用单引号包裹整个地址，key 用双引号。

确认导入成功：

```
terraform state list
```

可以看到带 key 的资源地址。

## 验证配置对齐

运行 plan 验证：

```
terraform plan
```

如果 plan 显示要修改标签，这是预期的——配置中声明了 tags，但预创建的资源组没有任何标签。执行 apply 使标签对齐：

```
terraform apply -auto-approve
```

验证标签已设置：

```
azlocal group show --name app-dev-rg
```

输出中应当能看到 Environment=dev、ManagedBy=Terraform 标签。

最终确认所有资源都在 Terraform 管理中：

```
terraform state list
```

确认列出了所有导入的资源后进入完成页。
