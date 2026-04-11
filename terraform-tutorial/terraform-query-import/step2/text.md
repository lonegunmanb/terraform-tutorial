# 第二步：terraform query 查询与导入

## terraform query 简介

上一步我们手动列出了桶名并编写 import 映射。但真实场景中，你的 AWS 账户可能有成百上千个资源，手动收集 ID 不现实。

Terraform v1.12 引入了 terraform query 命令和 .tfquery.hcl 查询文件：你只需声明"我要查询哪种类型的资源"，Terraform 借助 Provider 自动发现它们并生成 import 配置。

## 准备工作

先确认上一步导入的 prod 桶仍在状态中：

```
cd /root/workspace
terraform state list
```

## 编写查询文件

创建一个 .tfquery.hcl 文件，查询所有 S3 桶：

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

## 运行查询

先预览发现哪些资源：

```
terraform query
```

Terraform 会读取 .tf 文件中的 Provider 配置和 .tfquery.hcl 中的 list 块，通过 Provider 查询远端基础设施，打印发现的资源列表。

## 生成导入配置

terraform query 真正强大的地方在于自动生成配置：

```
terraform query -generate-config-out=generated.tf
```

查看生成的文件：

```
cat generated.tf
```

注意生成的配置有几个特点：

- 资源使用数字后缀命名（all_0、all_1...），而非以桶名为 key
- import 块使用 identity 块（而非旧版的 id 参数）来标识资源，这是 Terraform v1.12+ 的新格式
- resource 块包含了所有属性（包括 null 值和空 tags），需要手动清理

生成的配置类似：

```hcl
resource "aws_s3_bucket" "all_0" {
  bucket        = "app-prod-assets"
  force_destroy = null
  region        = "us-east-1"
  tags          = {}
  tags_all      = {}
}

import {
  to       = aws_s3_bucket.all_0
  provider = aws
  identity = {
    account_id = ""
    bucket     = "app-prod-assets"
    region     = "us-east-1"
  }
}

# ... 每个桶各有一组 resource + import 块
```

## 执行导入

先删除上一步手动写的 import 和 resource 块，避免与 generated.tf 冲突——只保留 provider 配置：

```
cat > main.tf <<'EOTF'
terraform {
  required_version = ">= 1.12"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = "test"
  secret_key = "test"

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    s3       = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
    sts      = "http://localhost:4566"
  }
}
EOTF
```

清空旧的状态（上一步导入的 prod 桶），让 generated.tf 重新导入所有桶：

```
rm -f terraform.tfstate terraform.tfstate.backup
```

预览计划：

```
terraform plan
```

应该看到所有桶都计划导入。执行导入：

```
terraform apply -auto-approve
```

确认输出包含 import 操作。

## 验证幂等性

导入完成后，再次 plan 验证配置与远端一致：

```
terraform plan
```

## 与 import for_each 的对比

上一步用的 import + for_each 方式需要你事先知道每个桶的名字，手动维护映射表。terraform query 的优势是**自动发现**——Provider 帮你列出所有匹配的资源。但生成的配置通常需要手动整理（统一命名、提取变量、组织模块结构）。

最佳实践是：先用 terraform query 发现和生成初始配置，然后重构为 for_each 模式，让代码更整洁。

## 注意事项

terraform query 功能需要：

- Terraform v1.12 或更高版本
- Provider 必须实现 resource identity 接口，对于 AWS Provider 需要 v6.x（~> 6.0）
- 查询配置文件必须使用 .tfquery.hcl 扩展名
- 并非所有资源类型都支持 list 查询——例如 aws_dynamodb_table 目前不支持

在没有 terraform query 支持的环境中，可以使用 AWS CLI 列出资源，结合 import + for_each 实现类似效果（正是第一步演示的方式）：

```
# 用 AWS CLI 列出所有桶名
awslocal s3 ls | awk '{print $3}'

# 用 AWS CLI 列出所有 DynamoDB 表
awslocal dynamodb list-tables --output text | tr '\t' '\n' | tail -n +2
```

然后手动将结果整理为 locals 映射表。
