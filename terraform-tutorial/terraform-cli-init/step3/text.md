# 第三步：切换 Backend 与状态迁移

本步骤使用独立的演示目录 /root/workspace/backend-demo，该目录已有本地 backend 的状态文件。你将把这份状态迁移到 S3（LocalStack 模拟）。

## 确认本地状态

进入演示目录，查看当前内容：

```
cd /root/workspace/backend-demo
ls -la
```

你应当看到：

- main.tf — 配置文件（null provider，无 backend 块）
- .terraform/ — 已用本地 backend 初始化
- terraform.tfstate — 本地状态文件（包含 null_resource.demo 的状态）
- backend.tf.example — S3 backend 配置示例

查看本地状态中的资源：

```
grep null_resource terraform.tfstate
```

## 查看 S3 Backend 配置示例

```
cat backend.tf.example
```

这份配置指向本地 LocalStack 的 S3 服务，tf-init-demo-state 桶已由后台脚本创建好。

确认 S3 桶存在：

```
awslocal s3 ls
```

## 切换到 S3 Backend 并迁移状态

先激活 backend 配置：

```
cp backend.tf.example backend.tf
```

运行 terraform init，Terraform 检测到存在本地状态且新 backend 尚无状态，会交互式询问是否迁移：

```
terraform init
```

你会看到类似如下提示：

```
Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "local" backend to the
  newly configured "s3" backend. No existing state was found in the newly
  configured "s3" backend. Do you want to copy this state to the new "s3"
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

查看 S3 桶中的状态文件：

```
awslocal s3 ls s3://tf-init-demo-state/demo/
```

下载远端状态并确认资源记录：

```
awslocal s3 cp s3://tf-init-demo-state/demo/terraform.tfstate /tmp/remote.json
grep null_resource /tmp/remote.json
```

查看本地目录，原来的 terraform.tfstate 已被重命名为 terraform.tfstate.backup：

```
ls -la
```

此时 Terraform 的活跃状态已在 S3，本地文件仅作备份保留。

## -reconfigure 的作用

-reconfigure 与 -migrate-state 的区别在于：它会直接重置 backend 配置，不尝试迁移任何状态。适用于你确定不需要保留旧 backend 状态的场景。

演示：删除 backend.tf 以恢复本地 backend，然后用 -reconfigure 跳过从 S3 迁移状态：

```
rm backend.tf
terraform init -reconfigure
```

Terraform 重新初始化为本地 backend，S3 中的状态文件依然存在，但不再被使用。
