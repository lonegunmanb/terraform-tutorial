# 规则管理与自定义策略

## 只运行指定规则

有时候你只想聚焦检查某几条规则，可以用 --check 参数：

```
checkov -d . --check CKV_AWS_21,CKV_AWS_145
```

这样只运行 S3 版本控制和加密相关的检查。在排查特定问题时非常有用。

## 跳过特定规则

在实际项目中，某些规则可能不适用于特定场景。比如我们的测试环境使用硬编码的假凭证，Checkov 可能会对此报警。

用 --skip-check 跳过这些规则：

```
checkov -d . --skip-check CKV_AWS_41
```

## 在代码中跳过规则（内联注释）

除了通过命令行参数跳过，还可以在 Terraform 代码中用注释的方式跳过特定规则。这种方式更精准，只对特定资源生效。

修改 main.tf，为 logs 桶跳过访问日志检查（日志桶本身通常不需要再配置日志）：

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

resource "aws_s3_bucket" "logs" {
  #checkov:skip=CKV_AWS_18:Log bucket does not need access logging
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

注意 logs 桶上方的 #checkov:skip=CKV_AWS_18:Log bucket does not need access logging 注释。冒号后面是跳过原因，这在团队协作中很重要——让其他人知道为什么跳过了这条检查。

运行扫描确认跳过生效：

```
checkov -d .
```

在输出中你会看到 Skipped checks 数量增加了，CKV_AWS_18 对 logs 桶的检查被标记为已跳过，并显示了跳过原因。

## 使用 --soft-fail 模式

在初始引入 Checkov 时，团队可能有大量历史代码未通过检查。使用 --soft-fail 可以让 Checkov 即使发现问题也返回退出码 0，不阻塞 CI 流程。

先恢复原始的、包含安全问题的代码，这样才能看到 soft-fail 的效果：

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

resource "aws_s3_bucket" "logs" {
  bucket        = "my-logs-bucket"
  force_destroy = true
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

现在不使用 --soft-fail 运行一次，确认有失败项并且退出码不为 0：

```
checkov -d . --compact
echo "退出码: $?"
```

退出码不为 0，说明 Checkov 检测到了安全问题。在 CI 中这会导致流水线失败。

现在加上 --soft-fail 再运行一次：

```
checkov -d . --soft-fail --compact
echo "退出码: $?"
```

退出码为 0，即使有失败的检查项。这在逐步推进安全合规时很有用——先以"警告"模式运行，待团队逐步修复后再切换为"阻塞"模式。

## 使用自定义 YAML 策略

Checkov 除了内置规则外，还支持自定义策略。背景脚本已经为你准备了一个自定义策略文件，用于检查所有 S3 桶是否包含 Environment 和 ManagedBy 标签。

查看自定义策略：

```
cat custom-policies/require_tags.yaml
```

这个 YAML 策略定义了：

- id: CUSTOM_AWS_1 — 策略的唯一标识符
- name — 策略描述
- severity: HIGH — 严重级别
- definition — 检查逻辑，使用 and 条件要求同时存在 Environment 和 ManagedBy 两个标签

使用 --external-checks-dir 参数加载自定义策略运行扫描：

```
checkov -d . --external-checks-dir custom-policies --check CUSTOM_AWS_1
```

你会看到 CUSTOM_AWS_1 对 data 桶通过（有 Environment 和 ManagedBy 标签），但对 logs 桶失败——因为当前的 main.tf 中 logs 桶没有 tags。这展示了如何用自定义策略强制执行组织内部的标签规范。

修复也很简单，为 logs 桶补上标签：

```
sed -i '/bucket.*=.*"my-logs-bucket"/a\
\n  tags = {\n    Environment = "dev"\n    ManagedBy   = "Terraform"\n  }' main.tf
```

再次验证：

```
checkov -d . --external-checks-dir custom-policies --check CUSTOM_AWS_1
```

CUSTOM_AWS_1 现在全部通过了。

## 输出为 JSON 格式

在 CI 管道中，JSON 格式更方便程序化处理：

```
checkov -d . -o json --compact 2>/dev/null | head -50
```

JSON 输出包含完整的检查结果结构，可以被自动化工具解析和处理。

## 总结

通过本步骤你学到了：

| 功能 | 命令 / 方式 |
|------|------------|
| 只运行指定规则 | --check CKV_AWS_21,CKV_AWS_145 |
| 跳过指定规则 | --skip-check CKV_AWS_41 |
| 内联跳过 | #checkov:skip=CKV_ID:reason |
| 软失败模式 | --soft-fail |
| 自定义策略 | --external-checks-dir path |
| JSON 输出 | -o json |
