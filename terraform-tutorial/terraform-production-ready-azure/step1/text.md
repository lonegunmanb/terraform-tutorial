# 第一步：观察大模块——Azure 三层架构的反面教材

## 查看单体配置

```bash
cd /root/workspace
wc -l main.tf
```

这个文件把 Resource Group、VNet、Subnet、NSG、Public IP、NIC、Linux VM、Storage Account 和 DNS Zone 全部放在一起。

```bash
head -120 main.tf
```

网络、安全、计算、存储、DNS 互相穿插。真实团队里，这会让职责边界和变更影响范围都变得很模糊。

## 部署并查看

```bash
terraform plan
terraform apply -auto-approve
```

## 用 azlocal 验证 Azure 资源

```bash
azlocal group list
azlocal network vnet list --resource-group webapp-dev-lab-rg
azlocal network vnet subnet list --resource-group webapp-dev-lab-rg --vnet-name webapp-dev-lab-vnet
azlocal vm list --resource-group webapp-dev-lab-rg
azlocal storage account list --resource-group webapp-dev-lab-rg
azlocal dns zone list --resource-group webapp-dev-lab-rg
```

## 查看状态地址

```bash
terraform state list
```

所有资源地址都是扁平的。你很难一眼看出哪些资源属于网络层，哪些属于虚拟机层，哪些属于安全或存储层。

下一步，我们用 moved 块把网络层和虚拟机层提取为模块。
