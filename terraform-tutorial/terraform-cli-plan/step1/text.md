# 第一步：理解 plan 输出

## 无变更时的输出

环境已预先 apply，进入工作目录先确认三个资源都在：

```
cd /root/workspace
awslocal s3 ls
awslocal dynamodb list-tables
```

此时配置与 state 完全一致，运行 plan 应显示无变更：

```
terraform plan
```

注意末尾的汇总行：

```
No changes. Your infrastructure matches the configuration.
```

## 触发修改（update）：观察 ~ 符号

向 app S3 桶的 tags 中增加一个新标签，模拟配置变更：

```
sed -i 's/ManagedBy   = "Terraform"/ManagedBy   = "Terraform"\n    Owner       = "platform-team"/' main.tf
```

再次运行 plan，这次会看到变更：

```
terraform plan
```

找到 aws_s3_bucket.app 资源行，注意行首的 ~ 符号，表示该资源将被原地修改（update in place）。

仔细阅读属性变更行：

- 带 + 的行是新增属性
- 带 - 的行是移除属性
- 带 ~ 的行是值发生变化的属性
- (known after apply) 表示该值只有在实际 apply 后才能确定

末尾的汇总行会显示：

```
Plan: 0 to add, 1 to change, 0 to destroy.
```

## 触发重建（replace）：观察 -/+ 符号

S3 的 bucket 名称是不可变属性，修改它会触发先销毁再重建（replace）。先看看直接改名会发生什么：

```
sed -i 's/bucket = "${var.app_name}-${var.environment}-logs-${var.suffix}"/bucket = "${var.app_name}-${var.environment}-logs2-${var.suffix}"/' main.tf
terraform plan
```

在 aws_s3_bucket.logs 资源行前，你会看到 -/+ 符号，以及 forces replacement 的提示。

汇总行变为：

```
Plan: 1 to add, 1 to change, 1 to destroy.
```

## 恢复配置

将 main.tf 恢复为原始状态，后续步骤继续使用：

```
cd /root/workspace
```

用编辑器（Theia）或直接重写恢复 main.tf，也可以用以下命令快速还原：

```
sed -i '/Owner.*platform-team/d' main.tf
sed -i 's/logs2-${var.suffix}/logs-${var.suffix}/' main.tf
terraform plan
```

确认末尾显示 No changes 后进入下一步。
