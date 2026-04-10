# 第二步：在不同 workspace 中部署独立资源

## 在 dev workspace 中部署

切换到 dev workspace 并部署资源：

```
cd /root/workspace
terraform workspace select dev
terraform apply -auto-approve
```

注意输出中资源名称包含 dev——因为 terraform.workspace 的值现在是 dev：

```
bucket_name = "myapp-dev-data"
table_name  = "myapp-dev-sessions"
```

## 创建 staging workspace 并部署

再创建一个 staging workspace：

```
terraform workspace new staging
terraform apply -auto-approve
```

输出中资源名称变为 staging：

```
bucket_name = "myapp-staging-data"
table_name  = "myapp-staging-sessions"
```

## 验证三套资源独立存在

此时三个 workspace（default / dev / staging）各有一套独立资源。用 AWS CLI 验证：

```
awslocal s3 ls
```

可以看到三个桶：

```
myapp-default-data
myapp-dev-data
myapp-staging-data
```

查看 DynamoDB 表：

```
awslocal dynamodb list-tables
```

同样有三张表。同一套 main.tf 配置，通过 workspace 机制创建了三组互不干扰的资源。

## terraform.workspace 的作用

回顾 main.tf 中的关键配置：

```
cat main.tf | grep -A3 "locals {"
```

local.env 取值为 terraform.workspace，所有资源名称都引用了 local.env。这就是 workspace 实现多环境的核心模式——用同一份配置，通过 workspace 名称区分资源。

列出所有 workspace 确认状态：

```
terraform workspace list
```

三个 workspace 全部存在，当前位于 staging（带星号标记）。
