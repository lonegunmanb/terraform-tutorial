# 第四步：-refresh-only 更新 state 与 -json 机器可读输出

## -refresh-only：只更新 state，不操作资源

当有人绕过 Terraform 直接在 AWS 控制台或 CLI 中删除了资源，state 文件就和远端不同步了。

-refresh-only apply 可以将 state 与远端实际情况对齐，而不重建被删除的资源。

模拟带外删除 app 桶：

```
cd /root/workspace
awslocal s3 rb s3://myapp-dev-app-lab --force
awslocal s3 ls
```

app 桶已不存在。先用普通 plan 看看 Terraform 的判断：

```
terraform plan
```

Terraform 检测到 app 桶消失，提议重新创建它（+ 符号）——这是正常的收敛行为。

但如果这次删除是有意为之，不想重建，可以用 -refresh-only 让 state 跟上实际状态：

```
terraform apply -refresh-only -auto-approve
```

-refresh-only 模式的 apply 输出会显示：

```
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
```

没有任何资源被创建、修改或销毁——只有 state 文件发生了变化。

验证 state 中 app 桶的记录已被移除：

```
terraform show | grep "aws_s3_bucket.app"
```

没有输出说明 state 和远端此时保持一致（app 桶都不存在）。

再运行 plan，现在应该显示 No changes（因为 state 已与远端对齐）：

```
terraform plan
```

重建 app 桶以恢复环境：

```
terraform apply -auto-approve
awslocal s3 ls
```

## -json：机器可读输出

-json 使 apply 的所有输出以 JSON Lines 格式打印，每行一个 JSON 对象，方便 CI 系统采集和解析。由于 -json 隐含 -input=false，使用时需要同时传入 -auto-approve 或计划文件。

先制造一个变更：

```
sed -i 's/ManagedBy   = "Terraform"/ManagedBy   = "Terraform"\n    Version     = "v2"/' main.tf
```

使用 -json 执行 apply：

```
terraform apply -auto-approve -json 2>&1 | tail -10
```

输出是一系列 JSON 对象。使用 grep 筛选关键消息——apply 完成事件：

```
terraform apply -auto-approve -json | grep '"type":"apply_complete"'
```

看到 apply_complete 对象，其中包含已变更的资源数量和耗时信息。

在 CI 脚本中可以结合 jq 解析失败原因、资源变更列表等，实现结构化的流水线日志。

恢复配置：

```
sed -i '/Version.*v2/d' main.tf
terraform apply -auto-approve
```

确认 No changes 后进入完成页。
