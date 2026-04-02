# 第三步：敏感值、临时变量与赋值方式

本步骤介绍 sensitive、ephemeral、nullable 参数，以及四种变量赋值方式和优先级。

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

注意输出中 db_password 显示为 (sensitive value)，而 deployment_label 中包含了 db_password 引用的部分也会被标记为 sensitive。

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

## 四种赋值方式

### 方式 1：命令行参数 -var

```bash
terraform plan -var="app_name=cli-app" -var="replica_count=3"
```

观察 app_name 和 replica_count 的值被覆盖了。

### 方式 2：参数文件 .tfvars

查看已准备好的参数文件：

```bash
cat dev.tfvars
```

使用 -var-file 指定参数文件：

```bash
terraform plan -var-file="dev.tfvars"
```

app_name 变成了 "web-frontend"，replica_count 变成了 5——这些值来自 dev.tfvars 文件。

> 提示：名为 terraform.tfvars 或 *.auto.tfvars 的文件会被自动加载，无需 -var-file。

### 方式 3：环境变量 TF_VAR_

```bash
export TF_VAR_app_name="env-app"
export TF_VAR_replica_count=10
terraform plan
```

环境变量使用 TF_VAR_ 前缀加上变量名。这种方式特别适合在 CI/CD 中传递敏感数据。

用完后清理环境变量：

```bash
unset TF_VAR_app_name TF_VAR_replica_count
```

### 方式 4：交互式输入

当变量没有默认值且未通过其他方式赋值时，Terraform 会在终端提示输入（本示例所有变量都有默认值，所以不会触发）。

## 赋值优先级

当多种方式同时设置同一变量时，后者覆盖前者（优先级从低到高）：

1. 环境变量
2. terraform.tfvars
3. terraform.tfvars.json
4. *.auto.tfvars（按字母序）
5. -var 和 -var-file 命令行参数

验证优先级——同时使用环境变量和 -var：

```bash
export TF_VAR_app_name="from-env"
terraform plan -var="app_name=from-cli"
```

观察输出：app_name 是 "from-cli"，因为命令行参数优先级高于环境变量。

```bash
unset TF_VAR_app_name
```
