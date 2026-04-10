# 第三步：Workspace 切换与状态隔离原理

## 切换 workspace 查看不同 state

在不同 workspace 之间切换，查看各自的 state：

```
cd /root/workspace
terraform workspace select default
terraform show | grep "bucket ="
```

输出 myapp-default-data——default workspace 只知道自己的资源。

```
terraform workspace select dev
terraform show | grep "bucket ="
```

输出 myapp-dev-data——dev workspace 只看到 dev 的资源。

```
terraform workspace select staging
terraform show | grep "bucket ="
```

输出 myapp-staging-data。每个 workspace 的 state 完全独立，互不可见。

## 查看 state 文件存储结构

Terraform 在本地以目录结构存储不同 workspace 的 state：

```
find /root/workspace -name "terraform.tfstate" -o -name "terraform.tfstate.d" | head -20
```

```
ls -la terraform.tfstate
ls -la terraform.tfstate.d/
ls -la terraform.tfstate.d/dev/
ls -la terraform.tfstate.d/staging/
```

存储结构为：

- default workspace → 根目录的 terraform.tfstate
- 其他 workspace → terraform.tfstate.d/NAME/terraform.tfstate

这也是官方文档所说的"workspace 在技术层面等于重命名 state 文件"的含义。

## 在一个 workspace 中修改配置

在 staging workspace 中修改资源（给 DynamoDB 表添加 TTL）：

```
terraform workspace select staging
cat >> main.tf <<'EOF'

resource "aws_dynamodb_table_item" "test_item" {
  table_name = aws_dynamodb_table.sessions.name
  hash_key   = aws_dynamodb_table.sessions.hash_key

  item = <<ITEM
{
  "SessionID": {"S": "test-session-001"},
  "CreatedAt": {"S": "2025-01-01T00:00:00Z"}
}
ITEM
}
EOF
```

在 staging 中 apply 这个变更：

```
terraform apply -auto-approve
```

staging workspace 多了一个 DynamoDB item。

切到 dev 看看：

```
terraform workspace select dev
terraform plan
```

dev workspace 也看到配置中多了一个 resource 块，plan 显示需要创建这个 item。这说明所有 workspace 共享同一份配置文件——配置变更对所有 workspace 可见，但 state 各自独立。

恢复配置，删除刚才添加的 resource 块：

```
head -n $(grep -n "^resource \"aws_dynamodb_table_item\"" main.tf | cut -d: -f1 | head -1 | xargs -I{} expr {} - 1) main.tf > main.tf.tmp && mv main.tf.tmp main.tf
```

在 staging 中清理掉那个 item：

```
terraform workspace select staging
terraform apply -auto-approve
```

确认三个 workspace 都回到只有 S3 桶和 DynamoDB 表的状态。
