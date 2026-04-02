# 第三步：敏感值与临时资源

本步骤通过对比 sensitive 和 ephemeral 两种方式，展示如何安全管理密码。

## 查看示例代码

```bash
cd /root/workspace/step3
cat main.tf
```

代码中用两种方式将密码存入 Secrets Manager，形成对比：

- 方式 A（sensitive）：用 secret_string 存储——值会写入状态文件
- 方式 B（ephemeral）：用 ephemeral 随机生成密码 + secret_string_wo（write-only 属性）存储——值不会写入状态文件

### sensitive 变量

将 sensitive 设为 true 后，Terraform 在 plan 和 apply 输出中会隐藏该变量的值：

```hcl
variable "db_password" {
  type      = string
  sensitive = true
}
```

> 重要：sensitive 只影响命令行输出。Terraform 仍然会将敏感数据以明文记录在状态文件中。

### 执行 apply 并验证

```bash
terraform apply -auto-approve
```

terraform state show 会隐藏 sensitive 值，显示为 (sensitive value)。要看到真实内容，需要直接查看状态文件。

先看方式 A——用 secret_string（普通属性）存储密码：

```bash
cat terraform.tfstate | jq '.resources[] | select(.name=="sensitive_demo" and .type=="aws_secretsmanager_secret_version") | .instances[0].attributes | {secret_string}'
```

你会看到 secret_string 字段包含明文密码 "super-secret-123"。这就是 sensitive 的局限：它只遮住 CLI 输出，数据仍然以明文存储在状态文件中。

再看方式 B——用 secret_string_wo（write-only 属性）存储密码：

```bash
cat terraform.tfstate | jq '.resources[] | select(.name=="ephemeral_demo" and .type=="aws_secretsmanager_secret_version") | .instances[0].attributes | {secret_string_wo}'
```

你会发现 secret_string_wo 的值为 null！write-only 属性只在 apply 时发送给 API，不会记录到状态文件中。

### ephemeral 资源（Terraform >= 1.10）

列出状态中的所有资源：

```bash
terraform state list
```

你只会看到四个普通 resource，而看不到 ephemeral 资源（random_password 和 aws_secretsmanager_secret_version）。ephemeral 资源的值只在当前运行期间存在，运行结束后彻底消失。

代码中使用了两个 ephemeral 资源：

```hcl
ephemeral "random_password" "db_password" {
  length           = 16
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

ephemeral "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret_version.ephemeral_demo.secret_id
}
```

- random_password 每次运行时生成新密码，不持久化
- aws_secretsmanager_secret_version 从 Secrets Manager 读回密码，也不持久化

::: tip
在真实场景中，ephemeral 读回的密码可以传给资源的 write-only 属性（如 aws_db_instance 的 password_wo），实现端到端零持久化。
:::

### sensitive vs ephemeral 对比

| 特性 | sensitive | ephemeral 资源 |
|------|-----------|----------------|
| plan/apply 输出中隐藏 | 是 | 是 |
| 状态文件中记录 | 是（明文） | 否 |
| 运行结束后可读取 | 是 | 否 |

简单来说：sensitive 是"遮住眼睛"，数据仍在状态文件中；ephemeral 资源搭配 write-only 属性则彻底不持久化。

### nullable 参数

nullable 默认为 true，允许变量接受 null 值。设为 false 后，即使显式传入 null，Terraform 也会使用默认值：

```hcl
variable "region" {
  type     = string
  default  = "us-east-1"
  nullable = false
}
```
