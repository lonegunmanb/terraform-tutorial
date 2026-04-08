# 第四步：-var / -var-file 变量注入与 -detailed-exitcode

## -var：命令行临时覆盖变量

先查看当前变量默认值和资源名称：

```
cd /root/workspace
terraform plan | grep "bucket ="
```

用 -var 把 environment 覆盖为 staging，预览名称会变成什么：

```
terraform plan -var 'environment=staging'
```

由于 bucket 名称包含变量（${var.environment}），Terraform 会提出销毁 dev 桶并新建 staging 桶——这体现了 bucket 名称变更会触发 replace 的规律。

注意等号两侧不能有空格：

```
terraform plan -var 'environment = staging'
```

上面那条命令会报错，这是 -var 的语法要求。

同时覆盖多个变量：

```
terraform plan -var 'environment=staging' -var 'app_name=api'
```

## -var-file：从文件批量传入变量

查看已准备好的 tfvars 文件：

```
cat dev.tfvars
cat prod.tfvars
```

用 dev.tfvars 规划（与默认值相同，应该无变更）：

```
terraform plan -var-file=dev.tfvars
```

用 prod.tfvars 规划（environment 变成 prod，所有资源名都会变化）：

```
terraform plan -var-file=prod.tfvars
```

观察 plan 输出，app 桶、logs 桶和 DynamoDB 表的名称全部变化，每个资源都会触发 replace（-/+），汇总应为：

```
Plan: 3 to add, 0 to change, 3 to destroy.
```

## -detailed-exitcode：脚本化判断变更

普通情况下 terraform plan 成功退出码始终为 0，脚本无法区分"有变更"和"无变更"。

先确认当前无变更的退出码：

```
terraform plan
echo "Exit code: $?"
```

应输出 Exit code: 0。

现在加 -detailed-exitcode，语义变为三态：

```
terraform plan -detailed-exitcode
echo "Exit code: $?"
```

无变更时退出码为 0（不是 1 或 2）。

添加一个配置变更来产生非空计划：

```
sed -i 's/ManagedBy   = "Terraform"/ManagedBy   = "Terraform"\n    Version     = "v2"/' main.tf
terraform plan -detailed-exitcode
echo "Exit code: $?"
```

有变更时退出码为 2。表示"成功且有变更需要 apply"。

在 CI 脚本中的典型用法：

```
terraform plan -detailed-exitcode -out=tfplan
RC=$?
if [ $RC -eq 0 ]; then
  echo "无变更，跳过 apply"
elif [ $RC -eq 2 ]; then
  echo "有变更，触发 apply 流程"
else
  echo "plan 执行失败"
  exit 1
fi
```

恢复配置：

```
sed -i '/Version.*v2/d' main.tf
terraform plan
```

确认输出 No changes 后进入完成页。
