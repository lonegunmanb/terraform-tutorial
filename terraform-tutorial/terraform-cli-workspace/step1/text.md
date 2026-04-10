# 第一步：默认 workspace 与基础命令

## 查看当前 workspace

进入工作目录，查看当前处于哪个 workspace：

```
cd /root/workspace
terraform workspace show
```

输出 default——每个初始化过的 Terraform 工作目录都自带一个名为 default 的默认 workspace。

## 列出所有 workspace

```
terraform workspace list
```

输出只有一个 workspace，且用星号标记为当前 workspace：

```
* default
```

## 在 default workspace 中部署资源

查看 main.tf 中如何使用 terraform.workspace：

```
grep "terraform.workspace" main.tf
```

配置使用了 terraform.workspace 作为资源名称的一部分（local.env = terraform.workspace），这意味着不同 workspace 创建的资源名称不同。

在 default workspace 中创建资源：

```
terraform apply -auto-approve
```

Apply 完成后，注意输出中的资源名称包含 default：

```
bucket_name = "myapp-default-data"
table_name  = "myapp-default-sessions"
```

用 AWS CLI 验证资源已创建：

```
awslocal s3 ls
awslocal dynamodb list-tables
```

## 创建新 workspace

现在创建一个新的 workspace：

```
terraform workspace new dev
```

Terraform 输出：

```
Created and switched to workspace "dev"!

You're now on a new, empty workspace. Workspaces isolate their state,
so if you run "terraform plan" Terraform will not see any existing state
for this configuration.
```

注意两个关键信息：创建后自动切换到新 workspace，且新 workspace 的 state 是空的。

确认当前 workspace 已切换：

```
terraform workspace show
```

列出所有 workspace：

```
terraform workspace list
```

输出中 dev 前面有星号——当前已在 dev workspace。

运行 plan 看看 Terraform 认为需要做什么：

```
terraform plan
```

Plan 显示需要创建 2 个资源——因为 dev workspace 的 state 是空的，Terraform 看不到 default workspace 中已创建的资源。这就是 workspace 状态隔离的核心机制。

切回 default workspace，确认原有资源仍在：

```
terraform workspace select default
terraform show | head -5
```

default workspace 的 state 完好无损。
