# 配置规则、修复问题与自定义规则

## 创建 tflint 配置文件

tflint 通过 .tflint.hcl 配置文件管理规则和插件。创建一个启用推荐规则集并额外开启命名和文档规则的配置：

```
cat > .tflint.hcl <<'EOF'
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

rule "terraform_naming_convention" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}
EOF
```

preset = "recommended" 会启用一组推荐的 Terraform 语言规则，包括：

- terraform_deprecated_interpolation — 废弃插值语法检测
- terraform_required_providers — 必须声明 source 和 version
- terraform_required_version — 必须声明 required_version
- terraform_typed_variables — variable 必须声明 type
- terraform_unused_declarations — 未使用的声明检测

terraform_naming_convention、terraform_documented_outputs、terraform_documented_variables 不在 recommended 预设中，所以我们在配置文件中手动启用了它们。

## 初始化并运行

tflint 的插件机制和 Terraform 类似，需要先 init 下载插件：

```
tflint --init
```

然后运行检查：

```
tflint
```

tflint 会输出多条警告。让我们逐一分析：

### 废弃的插值语法

terraform_deprecated_interpolation 规则报告了两处问题："\${var.bucket_name}" 和 "\${var.environment}" 应改为 var.bucket_name 和 var.environment。这是 Terraform 0.12+ 以来的推荐写法，去掉不必要的 "\${}" 包裹。注意输出中带有 [Fixable] 标记，表示这些问题可以自动修复。

### 命名规范

terraform_naming_convention 规则报告 MyBucket 不符合 snake_case 命名规范。Terraform 社区约定所有标识符使用 snake_case（小写加下划线），如 my_bucket。noType 变量名也违反了这一规范。

### 未声明类型的 variable

terraform_typed_variables 规则报告 bucket_name 和 noType 两个变量没有声明 type。明确声明类型可以防止类型错误，也让代码更易读。

### 缺少 description

terraform_documented_variables 规则报告 bucket_name 和 environment 变量没有 description；terraform_documented_outputs 规则报告 bucket_id 没有 description。为变量和输出添加描述是提高代码可维护性的重要实践。

### 未使用的声明

terraform_unused_declarations 规则报告 unused_var 和 noType 被声明但从未引用。未使用的声明是代码噪音，应该及时清理。

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

1. "\${var.bucket_name}" 改为 var.bucket_name（修复废弃插值语法）
2. "\${var.environment}" 改为 var.environment（修复废弃插值语法）
3. MyBucket 改为 my_bucket（修复 snake_case 命名规范）
4. 为 bucket_name 添加了 type（修复未声明类型）
5. 为 bucket_name、environment 添加了 description（修复缺少描述）
6. 为 bucket_id 添加了 description（修复缺少描述）
7. 删除了 unused_var 和 noType（修复未使用的声明）

注意：logs bucket 中的 "\${var.bucket_name}-logs" 保留了 "\${}"，因为这里是字符串拼接，不是简单变量引用。

## 验证修复结果

```
tflint
```

现在应该没有警告或错误了！

## 自定义规则：禁用特定规则

有时候团队可能不需要某些规则。比如，如果团队习惯了 "\${}" 插值语法，可以关闭废弃语法检查：

```
cat > .tflint.hcl <<'EOF'
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

rule "terraform_naming_convention" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_deprecated_interpolation" {
  enabled = false
}
EOF
```

运行检查看看效果：

```
tflint --init
tflint
```

terraform_deprecated_interpolation 的检查不再生效了。

恢复完整规则，为下一步做准备：

```
cat > .tflint.hcl <<'EOF'
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}
EOF
```
