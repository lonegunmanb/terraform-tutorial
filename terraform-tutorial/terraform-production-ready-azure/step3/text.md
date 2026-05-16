# 第三步：提取存储层和 DNS 层

## 查看新增模块

```bash
find /root/stage/step3/modules -name "*.tf" | sort
```

storage 模块管理 Storage Account 和 Container，dns 模块管理 Azure DNS Zone。

```bash
cat /root/stage/step3/modules/storage/main.tf
cat /root/stage/step3/modules/dns/main.tf
```

## 应用重构

```bash
cp -r /root/stage/step3/modules/* /root/workspace/modules/
cp /root/stage/step3/main.tf /root/workspace/
cp /root/stage/step3/moved.tf /root/workspace/
terraform init
terraform plan
terraform apply -auto-approve
```

再次检查状态：

```bash
terraform state list
```

Storage 和 DNS 资源也已经进入各自模块。
