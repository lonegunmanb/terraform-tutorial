# 编写策略并检测不合规配置

## 进入工作目录

```
cd /root/workspace
```

## 理解 Conftest 的工作流程

Conftest 与 checkov 不同——它不直接扫描 .tf 源码，而是对 Terraform Plan 的 JSON 输出进行策略检查。这意味着它能看到 Terraform 即将执行的变更的完整数据，包括计算后的值。

工作流程分三步：

1. 生成 Terraform Plan 并导出为 JSON
2. 编写 Rego 策略文件
3. 用 Conftest 执行策略检查

## 查看 Terraform Plan JSON

环境初始化时已经为你生成了 tfplan.json。先看看它的结构：

```
cat tfplan.json | head -5
```

JSON 内容很长，我们关注其中的 resource_changes 字段——它记录了所有即将创建/修改/删除的资源：

```
cat tfplan.json | grep -o '"type":"[^"]*"' | sort -u
```

可以看到计划创建的资源类型。接下来用 Conftest 检查这些资源是否合规。

## 查看预写好的 Rego 策略

环境中已准备了三条策略文件，放在 policy/ 目录下：

```
ls policy/
```

### 版本控制策略

```
cat policy/s3_versioning.rego
```

这条策略的逻辑是：遍历 resource_changes 中所有 aws_s3_bucket 类型的创建操作，检查是否有对应的 aws_s3_bucket_versioning 资源引用了该桶。如果没有，就报告违规。

### 加密策略

```
cat policy/s3_encryption.rego
```

类似地，检查每个 S3 桶是否有对应的 aws_s3_bucket_server_side_encryption_configuration 资源。

### 标签策略

```
cat policy/s3_tags.rego
```

这条策略要求每个 S3 桶的 tags 中必须包含 Environment 和 ManagedBy 两个标签。注意它直接读取 resource.change.after.tags 字段——这是 Terraform Plan JSON 中资源创建后的属性值。

## 运行 Conftest 检查

```
conftest test tfplan.json
```

Conftest 会输出 FAIL 信息，列出所有违反策略的资源。你应该能看到：

- data 桶和 logs 桶都缺少版本控制配置
- data 桶和 logs 桶都缺少加密配置
- logs 桶缺少必需标签（data 桶有 Environment 和 ManagedBy 标签，所以通过了）

每条 FAIL 消息前的路径表示它来自 policy/ 目录中的哪个策略文件。

## 使用 table 格式查看

table 格式让结果更清晰：

```
conftest test -o table tfplan.json
```

## 修复不合规配置

根据 Conftest 的报告，修复所有问题。为两个桶添加版本控制、加密和标签：

```
cat > main.tf <<'EOF'
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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
    s3  = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}

resource "aws_s3_bucket" "data" {
  bucket        = "my-data-bucket"
  force_destroy = true

  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket" "logs" {
  bucket        = "my-logs-bucket"
  force_destroy = true

  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Deployment environment"
}

output "data_bucket_id" {
  value       = aws_s3_bucket.data.id
  description = "The ID of the data bucket"
}

output "logs_bucket_id" {
  value       = aws_s3_bucket.logs.id
  description = "The ID of the logs bucket"
}
EOF
```

我们做了以下修改：

1. 为两个桶都添加了 aws_s3_bucket_versioning（版本控制）
2. 为两个桶都添加了 aws_s3_bucket_server_side_encryption_configuration（加密）
3. 为 logs 桶补充了 Environment 和 ManagedBy 标签

## 重新生成 Plan 并验证

```
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > tfplan.json
conftest test -o table tfplan.json
```

所有策略应该都通过了。这就是 Conftest 的核心流程：编写策略 → 生成 Plan → 运行检查 → 修复 → 重新验证。
