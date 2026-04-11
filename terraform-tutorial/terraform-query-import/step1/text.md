# 第一步：使用 import + for_each 批量导入 S3 桶

## 查看已有资源

进入工作目录，先看看 LocalStack 中已经存在哪些资源：

```
cd /root/workspace
awslocal s3 ls
```

应该看到 5 个 S3 桶（app-prod-data、app-prod-logs、app-prod-assets、app-staging-data、app-staging-logs）。

```
awslocal dynamodb list-tables
```

还有 2 个 DynamoDB 表（app-prod-sessions、app-prod-cache）。

这些资源目前不受 Terraform 管理。查看当前 Terraform 状态：

```
terraform state list 2>/dev/null || echo "状态文件中没有任何资源"
```

## 编写 import 块批量导入 prod 桶

我们先导入 3 个 prod 环境的 S3 桶。使用 import 块的 for_each——在代码重构一章中介绍过，它可以用一个映射表批量声明导入：

```
cat >> main.tf <<'EOF'

# ── 批量导入已有 S3 桶 ──

locals {
  prod_buckets = {
    data   = "app-prod-data"
    logs   = "app-prod-logs"
    assets = "app-prod-assets"
  }
}

import {
  for_each = local.prod_buckets
  to       = aws_s3_bucket.prod[each.key]
  id       = each.value
}

resource "aws_s3_bucket" "prod" {
  for_each = local.prod_buckets
  bucket   = each.value
}
EOF
```

这里做了三件事：
1. 用 locals 定义资源 ID 映射（key 是 Terraform 中的标识，value 是 AWS 中的桶名）
2. import 块用 for_each 遍历映射，声明"把桶 X 导入到 aws_s3_bucket.prod[key]"
3. resource 块同样用 for_each，声明 Terraform 管理这些桶

## 预览导入计划

```
terraform plan
```

输出应该显示：

```
Plan: 3 to import, 0 to add, 0 to change, 0 to destroy.
```

这表示 Terraform 发现了 3 个已有资源，计划将它们导入状态，不会创建、修改或销毁任何东西。

## 执行导入

```
terraform apply -auto-approve
```

确认输出包含：

```
Apply complete! Resources: 3 imported, 0 added, 0 changed, 0 destroyed.
```

验证状态文件：

```
terraform state list
```

应该看到 3 个桶已在状态中：

```
aws_s3_bucket.prod["assets"]
aws_s3_bucket.prod["data"]
aws_s3_bucket.prod["logs"]
```

## 导入后的幂等性验证

再次 plan，确认没有变更：

```
terraform plan
```

输出应该是 "No changes"。这说明我们的 resource 块配置与实际资源状态完全一致。

## 清理 import 块

导入完成后，import 块已经完成使命。可以保留作为历史记录，也可以移除。我们先保留它，进入下一步。
