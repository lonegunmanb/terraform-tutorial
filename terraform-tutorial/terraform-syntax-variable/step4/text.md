# 第四步：赋值方式与优先级

继续使用上一步的代码，体验四种变量赋值方式和它们的优先级。

## 进入工作目录

```bash
cd /root/workspace/step4
```

代码中有一个没有默认值的变量 project_id，我们用它来逐一体验各种赋值方式。

## 方式 1：命令行参数 -var

```bash
terraform plan -var="project_id=proj-001"
```

观察输出中 project_id 和 full_id 的值。再试试同时覆盖多个变量：

```bash
terraform plan -var="project_id=proj-001" -var="app_name=cli-app" -var="replica_count=3"
```

## 方式 2：参数文件 .tfvars

查看已准备好的参数文件：

```bash
cat dev.tfvars
```

使用 -var-file 指定参数文件：

```bash
terraform plan -var-file="dev.tfvars"
```

app_name 变成了 "web-frontend"，replica_count 变成了 5，project_id 变成了 "proj-dev"——这些值全部来自 dev.tfvars 文件。

> 提示：名为 terraform.tfvars 或 *.auto.tfvars 的文件会被自动加载，无需 -var-file。

## 方式 3：自动加载的 .auto.tfvars

创建一个自动加载的参数文件并验证效果：

```bash
cat > staging.auto.tfvars <<'EOF'
app_name      = "auto-loaded-app"
replica_count = 7
project_id    = "proj-auto"
EOF
```

不需要 -var-file，Terraform 自动加载 *.auto.tfvars 文件：

```bash
terraform plan
```

观察输出：app_name 是 "auto-loaded-app"，project_id 是 "proj-auto"——全部来自自动加载的文件。

用完后删除：

```bash
rm staging.auto.tfvars
```

## 方式 4：环境变量 TF_VAR_

```bash
export TF_VAR_app_name="env-app"
export TF_VAR_replica_count=10
export TF_VAR_project_id="proj-env"
terraform plan
```

环境变量使用 TF_VAR_ 前缀加上变量名。这种方式特别适合在 CI/CD 中传递敏感数据。

用完后清理环境变量：

```bash
unset TF_VAR_app_name TF_VAR_replica_count TF_VAR_project_id
```

## 方式 5：交互式输入

当变量没有默认值且未通过其他方式赋值时，Terraform 会在终端提示输入。project_id 没有默认值，试试直接运行：

```bash
terraform plan
```

Terraform 会显示变量的 description 并等待你输入：

```
var.project_id
  项目 ID（无默认值，必须赋值，否则提示输入）

  Enter a value:
```

输入一个值（比如 "proj-interactive"）后按回车，Terraform 继续执行。

## 赋值优先级

当多种方式同时设置同一变量时，后者覆盖前者（优先级从低到高）：

1. 环境变量
2. terraform.tfvars
3. terraform.tfvars.json
4. *.auto.tfvars（按字母序）
5. -var 和 -var-file 命令行参数

动手验证——同时使用三种方式给 app_name 赋值：

```bash
export TF_VAR_app_name="from-env"
cat > test.auto.tfvars <<'EOF'
app_name = "from-auto-tfvars"
EOF
terraform plan -var="app_name=from-cli" -var="project_id=proj-test"
```

观察输出：app_name 是 "from-cli"，因为 -var 优先级最高。

再去掉 -var，看 auto.tfvars 是否覆盖环境变量：

```bash
terraform plan -var="project_id=proj-test"
```

这次 app_name 是 "from-auto-tfvars"——auto.tfvars 优先级高于环境变量。

清理：

```bash
unset TF_VAR_app_name
rm test.auto.tfvars
```
