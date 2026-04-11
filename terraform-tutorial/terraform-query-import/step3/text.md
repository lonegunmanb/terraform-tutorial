# 第三步：练习——自己完成 DynamoDB 表和 staging 桶的批量导入

## 当前状态

经过第一步，我们已经导入了 3 个 prod S3 桶。确认上一步生成的 generated.tf 已删除（否则会与手动导入冲突）：

```
rm -f generated.tf
```

还有这些资源未纳入管理：

- S3 桶：app-staging-data、app-staging-logs
- DynamoDB 表：app-prod-sessions、app-prod-cache

检查当前状态：

```
terraform state list
awslocal s3 ls
awslocal dynamodb list-tables
```

## 练习 1：导入 staging S3 桶

请完成以下任务：

1. 在 main.tf 中添加一个 locals 块定义 staging 桶的映射（参考 prod_buckets 的写法）
2. 添加 import 块（使用 for_each）将两个 staging 桶导入
3. 添加对应的 resource 块
4. 执行 terraform plan 确认显示 "2 to import"
5. 执行 terraform apply 完成导入

---

## 练习 2：导入 DynamoDB 表

请完成以下任务：

1. 在 main.tf 中添加一个 locals 块定义 DynamoDB 表的映射
2. 添加 import 块和 resource 块

注意 DynamoDB 表的 resource 块需要更多属性：

- name — 表名
- billing_mode — 计费模式（这两个表都是 PAY_PER_REQUEST）
- hash_key — 分区键名（sessions 表用 SessionID，cache 表用 CacheKey）
- attribute 块 — 声明键的类型（S 表示字符串）

提示：两个表的 hash_key 不同，所以 resource 块中需要用 each.value 结构来区分，或者拆成两个单独的 import + resource。

---

## 练习 3：验证完整状态

全部导入完成后，运行：

```
terraform state list
```

确认所有 7 个资源（5 个 S3 桶 + 2 个 DynamoDB 表）都在状态中。

再运行：

```
terraform plan
```

确认显示 "No changes"——状态与配置完全一致。

---

## 参考答案

如果你卡住了，以下是完整的参考答案：

```
cat <<'ANSWER'
# ── staging S3 桶 ──

locals {
  staging_buckets = {
    data = "app-staging-data"
    logs = "app-staging-logs"
  }
}

import {
  for_each = local.staging_buckets
  to       = aws_s3_bucket.staging[each.key]
  id       = each.value
}

resource "aws_s3_bucket" "staging" {
  for_each = local.staging_buckets
  bucket   = each.value
}

# ── DynamoDB 表 ──
# 因为两个表的 hash_key 不同，需要用 object 映射

locals {
  dynamodb_tables = {
    sessions = {
      name     = "app-prod-sessions"
      hash_key = "SessionID"
    }
    cache = {
      name     = "app-prod-cache"
      hash_key = "CacheKey"
    }
  }
}

import {
  for_each = local.dynamodb_tables
  to       = aws_dynamodb_table.prod[each.key]
  id       = each.value.name
}

resource "aws_dynamodb_table" "prod" {
  for_each     = local.dynamodb_tables
  name         = each.value.name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = each.value.hash_key

  attribute {
    name = each.value.hash_key
    type = "S"
  }
}
ANSWER
```

将上述内容追加到 main.tf 后执行：

```
terraform plan
terraform apply -auto-approve
terraform state list
```

确认 7 个资源全部在状态中，plan 显示 "No changes"。
