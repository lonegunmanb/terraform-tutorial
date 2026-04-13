# 使用 AWS 插件扩展检查规则

tflint 的核心优势在于插件机制。内置的 terraform 插件只检查 Terraform 语言本身的规范，而云平台插件可以深入检查资源配置是否合理。接下来我们引入 AWS 插件，体验三条实用的扩展规则。

## 添加 AWS 插件

修改配置文件，加入 AWS 规则插件：

```
cat > .tflint.hcl <<'EOF'
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "aws" {
  enabled = true
  version = "0.38.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}
EOF
```

初始化下载 AWS 插件：

```
tflint --init
```

先运行一次看看 AWS 插件默认启用了哪些规则的检查结果：

```
tflint
```

AWS 插件有一些默认启用的规则（如 aws_s3_bucket_name），也有一些需要手动启用的高级规则。接下来我们逐一体验三条最实用的规则。

## 规则一：aws_resource_missing_tags — 强制资源标签

在企业环境中，标签管理至关重要——它关系到成本分摊、资源归属和合规审计。aws_resource_missing_tags 规则可以强制要求所有支持标签的 AWS 资源都必须包含指定标签。

这条规则默认不启用，需要手动配置：

```
cat > .tflint.hcl <<'EOF'
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "aws" {
  enabled = true
  version = "0.38.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

rule "aws_resource_missing_tags" {
  enabled = true
  tags = ["Team", "Project"]
}
EOF
```

运行检查：

```
tflint --init
tflint
```

你会看到 tflint 报告类似：

Notice: The resource is missing the following tags: "Project", "Team".

我们的 my_bucket 虽然有 Environment 和 ManagedBy 标签，但缺少 Team 和 Project；logs bucket 完全没有 tags 属性，问题更严重。

修复——为所有资源添加必需的标签：

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
    Team        = "platform"
    Project     = "demo"
  }
}

resource "aws_s3_bucket" "logs" {
  bucket        = "${var.bucket_name}-logs"
  force_destroy = true

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Team        = "platform"
    Project     = "demo"
  }
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

验证标签修复：

```
tflint
```

aws_resource_missing_tags 不再报告问题了。

## 规则二：aws_s3_bucket_name — S3 桶命名规范

AWS S3 桶名称全球唯一，命名混乱会导致管理困难。aws_s3_bucket_name 规则可以强制桶名称符合组织约定，例如要求前缀或匹配正则表达式。

在 .tflint.hcl 中添加这条规则：

```
cat > .tflint.hcl <<'EOF'
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "aws" {
  enabled = true
  version = "0.38.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

rule "aws_resource_missing_tags" {
  enabled = true
  tags = ["Team", "Project"]
}

rule "aws_s3_bucket_name" {
  enabled = true
  prefix  = "acme-"
}
EOF
```

运行检查：

```
tflint --init
tflint
```

tflint 会报告：

Error: Bucket name "my-demo-bucket" does not have prefix "acme-"

这在大型组织中很常见——所有桶名称必须以组织前缀开头，防止命名冲突。

你还可以用正则表达式进一步约束命名格式。我们这里暂不修复它，继续体验下一条规则。

## 规则三：aws_provider_missing_default_tags — Provider 级别默认标签

比起在每个资源上重复写标签，更好的做法是在 AWS Provider 级别设置默认标签。aws_provider_missing_default_tags 规则可以强制要求 Provider 配置 default_tags，一劳永逸地给所有资源打上标签。

```
cat > .tflint.hcl <<'EOF'
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "aws" {
  enabled = true
  version = "0.38.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

rule "aws_resource_missing_tags" {
  enabled = true
  tags = ["Team", "Project"]
}

rule "aws_s3_bucket_name" {
  enabled = true
  prefix  = "acme-"
}

rule "aws_provider_missing_default_tags" {
  enabled = true
  tags    = ["Team", "Project"]
}
EOF
```

运行检查：

```
tflint --init
tflint
```

tflint 会报告 AWS Provider 缺少 default_tags 配置。在实际项目中，你可以在 provider 块中添加：

```
provider "aws" {
  # ...
  default_tags {
    tags = {
      Team    = "platform"
      Project = "demo"
    }
  }
}
```

这样所有资源会自动继承这些标签，无需在每个资源上重复声明。

## 总结：tflint 插件的价值

通过 AWS 插件，我们体验了三类不同层面的检查规则：

| 规则 | 用途 | 默认启用 |
|------|------|----------|
| aws_resource_missing_tags | 强制资源包含指定标签 | 否 |
| aws_s3_bucket_name | 强制 S3 桶命名规范 | 是 |
| aws_provider_missing_default_tags | 强制 Provider 配置默认标签 | 否 |

AWS 插件还提供了 700+ 条基于 SDK 验证的规则（如实例类型校验、区域校验等）和多条最佳实践规则（如 aws_instance_previous_type 禁用上一代实例类型、aws_lambda_function_deprecated_runtime 检查过时的 Lambda 运行时等），大部分默认启用。

tflint 的插件不限于 AWS —— Azure（tflint-ruleset-azurerm）和 GCP（tflint-ruleset-google）也有对应插件，配置方式完全一致。
