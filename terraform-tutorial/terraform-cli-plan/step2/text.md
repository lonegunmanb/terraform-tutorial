# 第二步：规划模式（-destroy 与 -refresh-only）

## -destroy：预览全量销毁

-destroy 模式创建一份目标为销毁所有受管资源的计划，是 terraform destroy 的预览版本：

```
cd /root/workspace
terraform plan -destroy
```

仔细阅读输出，你会看到：

- 三个资源行首均显示 - 符号
- 汇总行：Plan: 0 to add, 0 to change, 3 to destroy

这个模式让你在执行 terraform destroy 之前确认销毁范围，尤其在生产环境中非常重要。

## -refresh-only：模拟带外变更（out-of-band change）

"带外变更"是指绕过 Terraform 直接在控制台或 CLI 修改资源（例如手动删除一个桶）。下面模拟这个场景。

直接用 awslocal 删除 app 桶（模拟有人手动删除了这个资源）：

```
awslocal s3 rb s3://myapp-dev-app-lab --force
```

确认桶已删除：

```
awslocal s3 ls
```

现在运行普通的 terraform plan：

```
terraform plan
```

Terraform 会检测到 app 桶已经不存在，并提出重新创建它——符号为 +。这是正常的 plan 行为：将远端状态对齐到配置。

但如果这个删除是预期的，你想让 state 去掉这条记录而不是重新创建这个资源，就需要 -refresh-only：

```
terraform plan -refresh-only
```

输出会显示：

- aws_s3_bucket.app 将从 state 中移除（以 - 标记，但注意这只是 state 变更，不是资源操作）
- 汇总：这是一个 state 更新计划，不会新建或销毁任何实际资源

如果此时 apply 这份计划，结果只有一个：Terraform 的 state 文件会更新，移除 app 桶的记录，而远端什么都不会变。

## 恢复环境

重新创建被删除的桶，以便后续步骤使用：

```
terraform apply -auto-approve
awslocal s3 ls
```

确认三个 S3 桶和 DynamoDB 表都已就绪。
