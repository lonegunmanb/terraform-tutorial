# 基础扫描：发现安全问题并修复

## 进入工作目录

```
cd /root/workspace
```

## 查看当前代码

先看看我们的 Terraform 代码：

```
cat main.tf
```

这段代码定义了两个 S3 存储桶。看起来语法正确，terraform validate 也不会报错。但从安全角度来看，它存在多个问题。

## 用 Checkov 进行首次扫描

对当前目录执行安全扫描：

```
checkov -d .
```

Checkov 会输出扫描结果，包括通过和未通过的检查项。让我们理解输出格式：

- **Passed checks** — 资源通过了的安全规则
- **Failed checks** — 资源未通过的安全规则，这是需要关注的重点

每条失败记录包含：

- 规则 ID（如 CKV_AWS_19）和描述
- FAILED for resource — 指出哪个资源违规
- File — 违规代码的文件和行号
- Guide — 修复指南链接（如有）

## 理解常见的 S3 安全规则

在扫描结果中，你会看到类似以下的失败规则（具体规则可能因 Checkov 版本而异）：

**CKV_AWS_145 / CKV_AWS_19** — Ensure S3 bucket is encrypted（S3 桶必须开启加密）。未加密的存储桶中数据以明文存储，一旦泄露后果严重。

**CKV_AWS_21** — Ensure S3 bucket has versioning enabled（S3 桶必须开启版本控制）。版本控制防止数据被意外删除或覆盖，是数据保护的基本措施。

**CKV_AWS_18** — Ensure S3 bucket has access logging enabled（S3 桶必须开启访问日志）。访问日志记录谁在何时访问了桶中的数据，是安全审计的基础。

**CKV2_AWS_6** — Ensure S3 bucket has a public access block（S3 桶必须配置公共访问阻止）。防止桶被意外设置为公开可访问。

## 使用紧凑格式查看

如果失败项很多，可以使用 --compact 参数让输出更简洁：

```
checkov -d . --compact
```

紧凑模式不显示违规代码块，只显示规则 ID、描述和资源信息，方便快速浏览。

## 修复安全问题

根据 Checkov 的报告，我们来添加安全配置。创建修复后的代码：

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

# ── 日志桶（先定义，供 data 桶引用）──
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

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── 数据桶 ──
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

resource "aws_s3_bucket_logging" "data" {
  bucket        = aws_s3_bucket.data.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "data-access-logs/"
}

resource "aws_s3_bucket_public_access_block" "data" {
  bucket                  = aws_s3_bucket.data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
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

1. 为两个桶添加了 aws_s3_bucket_versioning（开启版本控制）
2. 为两个桶添加了 aws_s3_bucket_server_side_encryption_configuration（开启 KMS 加密）
3. 为 data 桶添加了 aws_s3_bucket_logging（访问日志写入 logs 桶）
4. 为两个桶添加了 aws_s3_bucket_public_access_block（阻止公共访问）
5. 为 logs 桶补充了 tags

## 验证修复结果

```
checkov -d . --compact
```

对比之前的扫描结果，大量安全规则现在已经通过。可能仍有少数规则失败（例如与 LocalStack 测试环境相关的规则），这在实际项目中可以通过跳过机制处理。

Checkov 的价值在于：这些安全问题 terraform validate 完全不会报告，只有专门的安全扫描工具才能发现。
