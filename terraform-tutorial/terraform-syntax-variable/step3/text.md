# 第三步：敏感值与临时变量

本步骤介绍 sensitive、ephemeral、nullable 参数。

## 查看示例代码

```bash
cd /root/workspace/step3
cat main.tf
```

### sensitive 参数

将 sensitive 设为 true 后，Terraform 在 plan 和 apply 输出中会隐藏该变量的值：

```hcl
variable "db_password" {
  type      = string
  sensitive = true
}
```

运行 plan 观察效果：

```bash
terraform plan
```

注意输出中 db_password 和 connection_string 都显示为 (sensitive value)——因为 connection_string 引用了 db_password，sensitive 会在表达式中传播。

> 重要：sensitive 只影响命令行输出。Terraform 仍然会将敏感数据以明文记录在状态文件中。

### ephemeral 参数（Terraform >= 1.10）

如果你希望敏感数据连状态文件都不写入，可以使用 ephemeral。临时变量的值在当前运行期间可用，但不会被持久化到状态文件或计划文件中：

```hcl
variable "session_token" {
  type      = string
  ephemeral = true
}
```

查看代码中的 session_token 变量和 auth_header 输出：

```bash
cat main.tf | grep -A 5 ephemeral
```

ephemeral 与 sensitive 的核心区别：

| 特性 | sensitive | ephemeral |
|------|-----------|----------|
| plan/apply 输出中隐藏 | 是 | 是 |
| 状态文件中记录 | 是（明文） | 否 |
| 运行结束后可读取 | 是 | 否 |

简单来说：sensitive 是"遮住眼睛"，数据仍在状态文件中；ephemeral 则彻底不持久化。

临时变量只能在特定上下文中引用（locals、provider 块、provisioner、临时输出等），不能直接赋给普通资源属性——因为资源属性会写入状态文件，违背了 ephemeral 的设计意图。

运行 plan 观察效果：

```bash
terraform plan
```

注意 auth_header 输出被标记为 ephemeral，不会出现在计划文件中。

### nullable 参数

nullable 默认为 true，允许变量接受 null 值。设为 false 后，即使显式传入 null，Terraform 也会使用默认值：

```hcl
variable "region" {
  type     = string
  default  = "us-east-1"
  nullable = false
}
```

## 运行 plan 综合观察

```bash
terraform plan
```

观察 plan 输出中：
- db_password 和 connection_string 显示为 (sensitive value)
- auth_header 被标记为 ephemeral
- region、app_name、app_label 正常显示
