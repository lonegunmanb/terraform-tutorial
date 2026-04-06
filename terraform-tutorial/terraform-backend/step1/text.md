# 第一步：默认本地后端

Terraform 默认使用 local 后端，将状态文件存储在当前工作目录中。让我们先体验这种默认行为。

## 查看代码

```bash
cd /root/workspace
cat main.tf
```

代码定义了两个 S3 存储桶：
- demo-app-bucket — 应用数据桶
- terraform-state-bucket — 状态存储桶，后续步骤将用它来存放 Terraform 状态文件

## 初始化并创建资源

```bash
terraform init
```

观察输出中的这一行：

```
Initializing the backend...
```

Terraform 自动选择了 local 后端，因为我们没有在 terraform 块中配置 backend。

现在创建资源：

```bash
terraform apply -auto-approve
```

## 探索本地状态文件

apply 完成后，查看当前目录中的文件：

```bash
ls -la *.tfstate*
```

你会看到 terraform.tfstate 文件——这就是本地后端存储状态的位置。查看它的内容：

```bash
cat terraform.tfstate | python3 -m json.tool | head -30
```

状态文件是一个 JSON 文件，记录了 Terraform 管理的所有资源。注意其中的 serial 字段——每次状态更新时递增，用于并发控制。

## 确认资源已创建

```bash
awslocal s3 ls
```

你应该能看到 demo-app-bucket 和 terraform-state-bucket 都已被创建。

```bash
terraform plan
```

输出应显示 No changes——代码、状态文件、真实环境三者一致。

## 理解本地后端的局限

本地后端意味着：

- 状态文件只存在于你的本地磁盘
- 如果另一位同事也想运行 terraform apply，他没有这份状态文件
- 没有状态锁定——如果两人同时操作，状态可能被破坏
- 状态文件可能包含敏感信息（密码、密钥），存储在本地不够安全

在下一步中，我们将把状态迁移到刚刚创建的 terraform-state-bucket 中，体验远程后端。
