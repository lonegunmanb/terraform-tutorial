# 第一步：观察大模块——三层架构的反面教材

## 看看这个"大泥球"

进入工作目录，查看这个把整套三层架构塞进一个文件的配置：

```bash
cd /root/workspace
wc -l main.tf
```

将近 500 行代码——Resource Group、VNet、子网、NSG、Load Balancer、Cosmos DB、Storage Account、Key Vault、Managed Identity——全部混在一起。

## 浏览各层资源

```bash
head -100 main.tf
```

先看网络层：Resource Group、VNet、4 个子网。

```bash
sed -n '120,190p' main.tf
```

再看 NSG：LB 安全组、App 安全组、Data 安全组，以及它们与子网的关联。注意安全规则的引用链：LB 允许外部 80 端口流量进入，App 只允许来自 LB 子网的 80 端口流量，Data 只允许来自 App 子网的 5432 端口流量。

这是三层架构安全隔离的核心——但在一个文件里，这些引用关系散落在几百行之间。

## 部署并查看

```bash
terraform plan
```

plan 输出有多少行？你能快速分辨哪些资源属于网络层、哪些属于 Web 层吗？

首次 apply 可能需要比较久（Cosmos DB 和 Storage Account 初始化较慢）：

```bash
terraform apply -auto-approve -parallelism=2
```

## 验证各层资源

```bash
azlocal group list
azlocal network vnet list --resource-group $(terraform output -raw resource_group_name)
azlocal network nsg list --resource-group $(terraform output -raw resource_group_name)
azlocal network lb list --resource-group $(terraform output -raw resource_group_name)
azlocal vm list --resource-group $(terraform output -raw resource_group_name)
azlocal storage account list --resource-group $(terraform output -raw resource_group_name)
azlocal cosmosdb list --resource-group $(terraform output -raw resource_group_name)
```

资源都创建成功了。现在想象几个场景：

**场景一**：安全审计要求你梳理 NSG 规则——谁能访问谁。在 500 行里，NSG 散落在中间位置，你需要反复跳转才能理清引用链。

**场景二**：网络团队只负责 VNet 和子网，但这个文件里还有 Key Vault 和 Cosmos DB 表。他们被迫拥有不需要的修改权限。

**场景三**：改 Load Balancer 规则时，你不小心改了同一行附近的 NSG 规则，plan 输出几十行，你没注意到那一行变更。

## 查看状态文件

```bash
terraform state list
```

所有资源地址都是扁平的。你能一眼看出哪些属于网络层、哪些属于 Web 层、哪些属于数据层吗？

## 大模块在三层架构下的五个问题

| 问题 | 在三层架构中的表现 |
|------|-----------------|
| 慢 | plan 需要查询所有层的所有资源状态 |
| 不安全 | 改数据层需要网络层和安全层的权限 |
| 高风险 | 改 LB 配置时可能误动 NSG 或 Storage |
| 难理解 | 网络/Web/数据/存储/安全混在一起 |
| 难测试 | 要测数据层，必须连带部署整个 VNet |

下一步，我们用 moved 块把网络层和 Web 层提取为模块——不销毁、不重建任何资源。
