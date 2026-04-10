# state rm：移除资源

state rm 让 Terraform "忘记"某个资源，但不会销毁远端对象。适用于资源已被其他工具接管、或不再需要 Terraform 管理的场景。

## 1. 当前状态

确认当前状态中的资源：

```
cd /root/workspace
terraform state list
```

我们将从状态中移除 aws_s3_bucket.data。

## 2. -dry-run 预览

```
terraform state rm -dry-run aws_s3_bucket.data
```

输出：

```
Would remove aws_s3_bucket.data
```

## 3. 执行 state rm

```
terraform state rm aws_s3_bucket.data
```

输出：

```
Removed aws_s3_bucket.data
Successfully removed 1 resource instance(s).
```

验证状态：

```
terraform state list
```

aws_s3_bucket.data 已不在列表中。

## 4. 远端对象仍然存在

虽然 Terraform 状态中已没有 data 桶，但远端仍然有：

```
awslocal s3 ls
```

你应该能看到 state-demo-data 桶仍然存在。state rm 只修改状态，不影响远端。

## 5. 观察 plan 的表现

如果配置中还保留了 aws_s3_bucket.data 的定义，Terraform 会怎样？

```
terraform plan
```

Terraform 会计划**重新创建** data 桶，因为状态中没有它的记录。

## 6. 同步配置 — 移除 resource 块

用预备好的配置替换（已移除 data 桶定义）：

```
cp /root/main-step3.tf /root/workspace/main.tf
```

再次运行 plan：

```
terraform plan
```

现在应该看到 No changes，因为配置和状态都不再包含 data 桶。

## 7. 如果需要重新接管？

假设你改变了主意，想让 Terraform 重新管理 data 桶。可以用 import 命令：

```
# 先在配置中重新添加 resource 块
cat >> main.tf <<'EOF'

resource "aws_s3_bucket" "data" {
  bucket = "state-demo-data"
  tags = {
    Name        = "Data Bucket"
    Environment = "staging"
  }
}
EOF
```

然后导入：

```
terraform import aws_s3_bucket.data state-demo-data
```

验证：

```
terraform plan
```

应该看到 No changes（或只有微小的属性差异）。这展示了 state rm 和 import 互为逆操作的关系。
