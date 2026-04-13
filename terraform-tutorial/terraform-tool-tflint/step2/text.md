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
- terraform_required_providers — 必须声明 source 和 version
- terraform_required_version — 必须声明 required_version
- terraform_typed_variables — variable 必须声明 type
- terraform_unused_declarations — 未使用的声明检测

注意：terraform_naming_convention（命名规范）、terraform_documented_outputs（output 必须有 description）、terraform_documented_variables（variable 必须有 description）等规则不在 recommended 预设中，需要手动启用。

## 初始化并运行

tflint 的插件机制和 Terraform 类似，需要先 init 下载插件：

```
tflint --init
```

然后运行检查：

```
tflint
```

tflint 会输出 6 条警告。让我们逐一分析：

### 废弃的插值语法（2 条）

terraform_deprecated_interpolation 规则报告了两处问题："\${var.bucket_name}" 和 "\${var.environment}" 应改为 var.bucket_name 和 var.environment。这是 Terraform 0.12+ 以来的推荐写法，去掉不必要的 "\${}" 包裹。注意输出中带有 [Fixable] 标记，表示这些问题可以自动修复。

### 未声明类型的 variable（2 条）

terraform_typed_variables 规则报告 bucket_name 和 noType 两个变量没有声明 type。明确声明类型可以防止类型错误，也让代码更易读。

### 未使用的声明（2 条）

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

针对 tflint 报告的 6 条问题，我们做了以下修改：

1. "\${var.bucket_name}" 改为 var.bucket_name（修复废弃插值语法）
2. "\${var.environment}" 改为 var.environment（修复废弃插值语法）
3. 为 bucket_name 添加了 type（修复未声明类型）
4. 删除了 unused_var 和 noType（修复未使用的声明）

同时作为良好实践，我们还做了几项改进：

5. MyBucket 改为 my_bucket（snake_case 命名规范）
6. 为所有 variable 和 output 添加了 description（文档完整性）

注意：logs bucket 中的 "\${var.bucket_name}-logs" 保留了 "\${}"，因为这里是字符串拼接，不是简单变量引用。

## 验证修复结果

```
tflint
```

现在应该没有警告或错误了！

## 自定义规则：启用与禁用

前面我们提到 terraform_naming_convention、terraform_documented_outputs 等规则不在 recommended 预设中。你可以在配置文件中手动启用它们：

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

运行检查：

```
tflint --init
tflint
```

因为我们修复代码时已经遵循了这些规范（snake_case 命名、添加了 description），所以检查通过。如果代码中仍有 MyBucket 这样的命名或缺少 description 的变量，这些规则就会报告警告。

你也可以禁用不需要的规则。比如，如果团队习惯了 "\${}" 插值语法，可以关闭废弃语法的检查：

```
rule "terraform_deprecated_interpolation" {
  enabled = false
}
```

恢复完整规则，为下一步做准备：

```
cat > .tflint.hcl <<'EOF'
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}
EOF
```
