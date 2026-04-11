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
EOF
```

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
```

## 生成导入配置

terraform query 真正强大的地方在于自动生成配置：

现在运行命令生成配置：

```
terraform query -generate-config-out=generated.tf
```

查看生成的文件：

```
cat generated.tf
```

这会创建 generated.tf 文件，包含每个发现的资源的 resource 块和 import 块。

注意生成的配置有几个特点：

- 资源使用数字后缀命名（filtered_0、filtered_1...），而非以桶名为 key
- import 块使用 identity 块（而非旧版的 id 参数）来标识资源，这是 Terraform v1.12+ 的新格式
- resource 块包含了所有属性（包括 null 值和空 tags），需要手动清理

生成的配置类似：

```hcl
resource "aws_s3_bucket" "filtered_0" {
  bucket        = "app-prod-assets"
  force_destroy = null
  region        = "us-east-1"
  tags          = {}
  tags_all      = {}
}

import {
  to       = aws_s3_bucket.filtered_0
  provider = aws
  identity = {
    account_id = ""
    bucket     = "app-prod-assets"
    region     = "us-east-1"
  }
}

# ... 每个桶各有一组 resource + import 块
```

## 从生成到导入的完整流程

1. 检查生成的 generated.tf，**清理冗余属性**（移除 null 值、空 tags、timeouts 块等）
2. 根据需要重命名资源（生成的 filtered_0、filtered_1 不够直观）
3. 将 import 和 resource 块合并到你的主配置中
4. 运行 terraform plan 确认只有 import 操作
5. 运行 terraform apply 完成导入
6. 删除 generated.tf 和不再需要的 import 块

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

本实验环境使用 MiniStack + AWS Provider v6.x，满足版本要求。但并非所有资源类型都支持 list 查询——例如 aws_dynamodb_table 目前不支持，所以本步只查询 S3 桶。对于不支持 query 的资源类型，仍需使用第一步和第三步演示的 import + for_each 方式。

在没有 terraform query 支持的环境中，可以使用 AWS CLI 列出资源，结合 import + for_each 实现类似效果（这正是第一步和第三步演示的方式）：

```
# 用 AWS CLI 列出所有桶名
awslocal s3 ls | awk '{print $3}'

# 用 AWS CLI 列出所有 DynamoDB 表
awslocal dynamodb list-tables --output text | tr '\t' '\n' | tail -n +2
```

然后手动将结果整理为 locals 映射表。
