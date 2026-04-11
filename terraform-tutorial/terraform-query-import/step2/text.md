# 第二步：编写 .tfquery.hcl 查询配置

## terraform query 简介

上一步我们手动列出了桶名并编写 import 映射。但真实场景中，你的 AWS 账户可能有成百上千个资源，手动收集 ID 不现实。

Terraform v1.12 引入了 terraform query 命令和 .tfquery.hcl 查询文件：你只需声明"我要查询哪种类型的资源"，Terraform 借助 Provider 自动发现它们并生成 import 配置。

## 编写查询文件

创建一个 .tfquery.hcl 文件，查询 S3 桶：

```
cat > discover.tfquery.hcl <<'EOF'
list "aws_s3_bucket" "all" {
  provider         = aws
  include_resource = true
  limit            = 50
}
EOF
```

这个查询会让 AWS Provider 列出最多 50 个 S3 桶。include_resource = true 表示返回完整的资源属性（不仅是标识）。

## 参数化查询

让查询更灵活——使用变量参数化：

```
cat > discover.tfquery.hcl <<'EOF'
variable "prefix" {
  type    = string
  default = "app-"
}

list "aws_s3_bucket" "filtered" {
  provider         = aws
  include_resource = true
  limit            = 100
}

list "aws_dynamodb_table" "all_tables" {
  provider         = aws
  include_resource = true
  limit            = 50
}
EOF
```

这样一次查询就能同时发现 S3 桶和 DynamoDB 表。

## 理解 terraform query 的输出

运行 terraform query 时，Terraform 会：

1. 读取当前目录的 .tf 文件获取 Provider 配置
2. 读取 .tfquery.hcl 文件中的 list 块
3. 通过 Provider 查询远端基础设施
4. 打印发现的资源列表

输出格式类似：

```
list.aws_s3_bucket.filtered:
  - app-prod-data
  - app-prod-logs
  - app-prod-assets
  - app-staging-data
  - app-staging-logs

list.aws_dynamodb_table.all_tables:
  - app-prod-sessions
  - app-prod-cache
```

## 生成导入配置

terraform query 真正强大的地方在于自动生成配置：

```
terraform query -generate-config-out=generated.tf
```

这会创建 generated.tf 文件，包含每个发现的资源的 import 块和 resource 块。

生成的配置类似：

```hcl
import {
  to = aws_s3_bucket.filtered["app-staging-data"]
  id = "app-staging-data"
}

resource "aws_s3_bucket" "filtered" {
  bucket = "app-staging-data"
}

import {
  to = aws_dynamodb_table.all_tables["app-prod-sessions"]
  id = "app-prod-sessions"
}

resource "aws_dynamodb_table" "all_tables" {
  name         = "app-prod-sessions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "SessionID"
  # ... 更多属性
}
```

## 从生成到导入的完整流程

1. 检查生成的 generated.tf，移除不需要的资源或只读属性
2. 将 import 和 resource 块合并到你的主配置中
3. 运行 terraform plan 确认只有 import 操作
4. 运行 terraform apply 完成导入
5. 删除 generated.tf 和不再需要的 import 块

## 与 import for_each 的对比

上一步用的 import + for_each 方式需要你事先知道每个桶的名字，手动维护映射表：

```hcl
locals {
  prod_buckets = {
    data   = "app-prod-data"    # 手动填写
    logs   = "app-prod-logs"    # 手动填写
    assets = "app-prod-assets"  # 手动填写
  }
}
```

terraform query 的优势是**自动发现**——你不需要一个个去查 AWS 控制台或 CLI，Provider 帮你列出所有匹配的资源。但生成的配置通常需要手动整理（统一命名、提取变量、组织模块结构）。

最佳实践是：先用 terraform query 发现和生成初始配置，然后重构为 for_each 模式，让代码更整洁。

## 注意事项

terraform query 功能需要：

- Terraform v1.12 或更高版本
- Provider 必须实现 resource identity 接口，对于 AWS Provider 需要 v6.x（~> 6.0）
- 查询配置文件必须使用 .tfquery.hcl 扩展名

本实验环境使用 MiniStack + AWS Provider v6.x，满足版本要求。但 terraform query 的实际查询能力取决于 MiniStack 对 resource identity API 的模拟程度——如果某些查询返回错误，属于模拟环境的正常限制。

在没有 terraform query 支持的环境中，可以使用 AWS CLI 列出资源，结合 import + for_each 实现类似效果（这正是第一步和第三步演示的方式）：

```
# 用 AWS CLI 列出所有桶名
awslocal s3 ls | awk '{print $3}'

# 用 AWS CLI 列出所有 DynamoDB 表
awslocal dynamodb list-tables --output text | tr '\t' '\n' | tail -n +2
```

然后手动将结果整理为 locals 映射表。
