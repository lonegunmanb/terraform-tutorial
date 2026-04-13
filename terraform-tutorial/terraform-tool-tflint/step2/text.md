# 配置规则、修复问题与自定义规则

## 创建 tflint 配置文件

tflint 通过 .tflint.hcl 配置文件管理规则和插件。创建一个启用推荐规则集的配置：

```
cat > .tflint.hcl <<'EOF'
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}
EOF
```

preset = "recommended" 会启用一组推荐的 Terraform 语言规则，包括：

- terraform_deprecated_interpolation — 废弃插值语法检测
- terraform_documented_outputs — output 必须有 description
- terraform_documented_variables — variable 必须有 description
- terraform_naming_convention — 命名必须使用 snake_case
- terraform_required_providers — 必须声明 source 和 version
- terraform_typed_variables — variable 必须声明 type
- terraform_unused_declarations — 未使用的声明检测

## 初始化并运行

tflint 的插件机制和 Terraform 类似，需要先 init 下载插件：

```
tflint --init
```

然后运行检查：

```
tflint
```

现在你应该能看到更多问题了！让我们逐一分析：

### 废弃的插值语法

terraform_deprecated_interpolation 规则会报告："\${var.bucket_name}" 应改为 var.bucket_name。这是 Terraform 0.12+ 以来的推荐写法，去掉不必要的 "\${}" 包裹。

### 未记录的 output/variable

terraform_documented_outputs 规则报告 bucket_id 没有 description；terraform_documented_variables 规则报告 bucket_name 没有 description。

### 未声明类型的 variable

terraform_typed_variables 规则会报告 bucket_name 没有声明 type。

### 命名规范

terraform_naming_convention 规则报告 MyBucket 不符合 snake_case 命名规范。

### 未使用的声明

terraform_unused_declarations 规则报告 unused_var 被声明但从未引用。

## 使用紧凑格式输出

在 CI 环境中，紧凑格式更容易解析：

```
tflint -f compact
```

每行一条问题，格式为：文件:行:列: 级别 - 消息 (规则名)。

## 修复代码中的问题

根据 tflint 的报告，我们来逐一修复。创建修复后的代码：

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

resource "aws_s3_bucket" "my_bucket" {
  bucket        = var.bucket_name
  force_destroy = true

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket" "logs" {
  bucket        = "${var.bucket_name}-logs"
  force_destroy = true
}

variable "bucket_name" {
  type        = string
  default     = "my-demo-bucket"
  description = "Name of the S3 bucket"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Deployment environment"
}

output "bucket_id" {
  value       = aws_s3_bucket.my_bucket.id
  description = "The ID of the main bucket"
}

output "logs_bucket_id" {
  value       = aws_s3_bucket.logs.id
  description = "The ID of the logs bucket"
}
EOF
```

我们做了以下修改：

1. MyBucket 改为 my_bucket（snake_case 命名）
2. "\${var.bucket_name}" 改为 var.bucket_name（移除废弃插值语法）
3. "\${var.environment}" 改为 var.environment
4. 为 bucket_name 添加了 type 和 description
5. 为 bucket_id 添加了 description
6. 删除了 unused_var 和 noType（未使用的变量）

注意：logs bucket 中的 "\${var.bucket_name}-logs" 保留了 "\${}"，因为这里是字符串拼接，不是简单变量引用。

## 验证修复结果

```
tflint
```

现在应该没有警告或错误了！

## 自定义规则：禁用特定规则

有时候团队可能不需要某些规则。比如，在示例代码中允许 output 不写 description：

```
cat > .tflint.hcl <<'EOF'
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

rule "terraform_documented_outputs" {
  enabled = false
}
EOF
```

重新初始化并检查：

```
tflint --init
tflint
```

即使我们把 output 的 description 去掉，tflint 也不会报告了。

恢复完整规则，为下一步做准备：

```
cat > .tflint.hcl <<'EOF'
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}
EOF
```
