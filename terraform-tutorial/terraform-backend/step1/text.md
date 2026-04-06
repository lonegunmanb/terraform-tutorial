# 第一步：默认本地后端

Terraform 默认使用 local 后端，将状态文件存储在当前工作目录中。让我们先体验这种默认行为。

## 初始化并创建资源

```bash
cd /root/workspace
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

## 理解本地后端的局限

本地后端意味着：

- 状态文件只存在于你的本地磁盘
- 如果另一位同事也想运行 terraform apply，他没有这份状态文件
- 没有状态锁定——如果两人同时操作，状态可能被破坏
- 状态文件可能包含敏感信息（密码、密钥），存储在本地不够安全

在接下来的步骤中，我们将把状态迁移到远程后端来解决这些问题。

## 确认资源已创建

```bash
awslocal s3 ls
```

你应该能看到 backend-demo-bucket 已被创建。同时确认 terraform 能正确管理它：

```bash
terraform plan
```

输出应显示 No changes——代码、状态文件、真实环境三者一致。
