# 第三步：切换 Backend 与状态迁移

本步骤使用独立的演示目录 /root/workspace/backend-demo，该目录已有本地 backend 的状态文件（环境初始化时已 apply 过一份资源）。你将把这份状态迁移到 azurerm backend（miniblue 模拟的 Azure Blob Container）。

## 确认本地状态

进入演示目录，查看当前内容：

```
cd /root/workspace/backend-demo
ls -la
```

你应当看到：

- main.tf — 配置文件（azurerm provider，无 backend 块）
- .terraform/ — 已用本地 backend 初始化
- terraform.tfstate — 本地状态文件（包含 azurerm_resource_group.demo 的状态）
- backend.tf.example — azurerm backend 配置示例

查看本地状态中的资源：

```
grep azurerm_resource_group terraform.tfstate
```

## 查看 azurerm Backend 配置示例

```
cat backend.tf.example
```

这份配置指向本地 miniblue 的 Storage Account：环境初始化时已经为你创建好资源组 tfstate-rg、Storage Account tfstateinit 与 Container tfstate。

确认状态存储资源都已就绪：

```
azlocal group list
azlocal storage account list --resource-group tfstate-rg
```

## 切换到 azurerm Backend 并迁移状态

先激活 backend 配置：

```
cp backend.tf.example backend.tf
```

运行 terraform init，Terraform 检测到存在本地状态且新 backend 尚无状态，会交互式询问是否迁移。注意 azurerm backend 还需要安装额外的依赖（hashicorp/azurerm 远端 backend 插件 + 处理 blob 的内部模块），所以会重新拉取相关组件：

```
terraform init
```

你会看到类似如下提示：

```
Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "local" backend to the
  newly configured "azurerm" backend. No existing state was found in the newly
  configured "azurerm" backend. Do you want to copy this state to the new "azurerm"
  backend? Enter "yes" to copy and "no" to start with an empty state.

  Enter a value:
```

输入 yes 并回车确认迁移。

## 在自动化场景中跳过交互式确认

在 CI/CD 或脚本中不方便交互时，可以用 -force-copy 跳过确认（相当于自动回答 yes）：

```
terraform init -force-copy
```

## 验证状态已迁移

azurerm backend 把状态以 blob 的形式写入 Container 中。通过 ARM API 查询 blob 列表确认：

```
curl -s \
  "http://localhost:4566/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/tfstate-rg/providers/Microsoft.Storage/storageAccounts/tfstateinit/blobServices/default/containers/tfstate/blobs?api-version=2023-01-01" \
  | jq .
```

也可以直接从 miniblue 的数据面下载 blob 内容，确认资源记录被正确写入：

```
curl -s "http://localhost:4566/tfstateinit/tfstate/demo/terraform.tfstate" -o /tmp/remote.json
grep azurerm_resource_group /tmp/remote.json
```

查看本地目录，原来的 terraform.tfstate 已被重命名为 terraform.tfstate.backup：

```
ls -la
```

此时 Terraform 的活跃状态已在 Azure Blob Container，本地文件仅作备份保留。

## -reconfigure 的作用

-reconfigure 与 -migrate-state 的区别在于：它会直接重置 backend 配置，不尝试迁移任何状态。适用于你确定不需要保留旧 backend 状态的场景。

演示：删除 backend.tf 以恢复本地 backend，然后用 -reconfigure 跳过从 azurerm backend 迁移状态：

```
rm backend.tf
terraform init -reconfigure
```

Terraform 重新初始化为本地 backend，azurerm backend 中的状态 blob 依然存在，但不再被使用。
