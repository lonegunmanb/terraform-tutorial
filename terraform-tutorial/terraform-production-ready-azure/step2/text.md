# 第二步：提取网络层和虚拟机层

## 查看预备好的模块

```bash
find /root/stage/step2 -name "*.tf" | sort
```

networking 模块封装 Resource Group、VNet 和三个 Subnet。web 模块封装 Public IP、NIC、NSG 关联和 Linux VM。

```bash
cat /root/stage/step2/moved.tf
```

moved 块告诉 Terraform 资源只是换了地址，不要销毁重建。

## 应用重构

```bash
cp -r /root/stage/step2/modules /root/workspace/
cp /root/stage/step2/main.tf /root/workspace/
cp /root/stage/step2/moved.tf /root/workspace/
terraform init
terraform plan
```

计划应显示 0 to add, 0 to change, 0 to destroy。

```bash
terraform apply -auto-approve
terraform state list
```

现在网络和虚拟机资源已经带上 module 前缀，职责边界更清楚。
