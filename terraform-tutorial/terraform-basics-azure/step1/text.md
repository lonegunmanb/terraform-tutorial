# 第一步：创建 Resource Group 与 Virtual Network

## 初始化并应用

进入工作目录，查看预置的 main.tf 配置文件：

```
cd /root/workspace
cat main.tf
```

这份配置定义了一个 Resource Group 和一个地址空间为 10.0.0.0/16 的 Virtual Network。接下来，初始化 Terraform 并创建它们：

```
terraform init
terraform apply -auto-approve
```

terraform init 会下载 azurerm Provider 插件；terraform apply 会真正创建资源。

执行完成后，你应该能看到类似输出：

```
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

resource_group_name = "TerraformTutorial-rg"
vnet_address_space = tolist([
  "10.0.0.0/16",
])
vnet_name = "TerraformTutorial-vnet"
```

## 用 azlocal 验证

azlocal 是 miniblue 自带的 CLI，走 HTTP 4566，无需证书。它的用法类似 LocalStack 的 awslocal。

查询刚创建的 Resource Group：

```
azlocal group list
```

你应该能看到名为 TerraformTutorial-rg 的资源组。

接下来查看 Virtual Network：

```
azlocal network vnet list --resource-group TerraformTutorial-rg
```

输出应该列出一个名为 TerraformTutorial-vnet 的 VNet，其 addressSpace.addressPrefixes 为 ["10.0.0.0/16"]。

> 💡 azlocal 与 Terraform 走的是同一个 miniblue 实例，因此它看到的就是 Terraform 刚刚创建的真实资源。
