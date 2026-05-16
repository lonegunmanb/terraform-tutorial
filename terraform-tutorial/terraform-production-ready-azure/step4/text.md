# 第四步：提取安全层并加入防护

## 完成模块化

```bash
cat /root/stage/step4/modules/security/main.tf
```

security 模块封装三个 Network Security Group。web 模块只消费 web_nsg_id，不再自己决定安全规则。

```bash
diff /root/workspace/moved.tf /root/stage/step4/moved.tf
```

## 查看内置防护

```bash
diff /root/workspace/modules/networking/variables.tf /root/stage/step4/modules/networking/variables.tf
diff /root/workspace/modules/storage/variables.tf /root/stage/step4/modules/storage/variables.tf
diff /root/workspace/modules/storage/main.tf /root/stage/step4/modules/storage/main.tf
diff /root/workspace/modules/web/main.tf /root/stage/step4/modules/web/main.tf
```

这一步加入了 CIDR 校验、Storage Account 命名校验、存储层 postcondition，以及 VM 规格 precondition。

## 应用最终重构

```bash
cp -r /root/stage/step4/modules/* /root/workspace/modules/
cp /root/stage/step4/main.tf /root/workspace/
cp /root/stage/step4/moved.tf /root/workspace/
terraform init
terraform plan
terraform apply -auto-approve
```

## 测试防护

```bash
terraform plan -var="vnet_cidr=not-a-cidr"
terraform plan -var="app_name=UPPERCASE"
```

这些错误会在真正调用 Azure API 之前被 Terraform 拦截。
