# 第一步：理解 plan 输出

## 无变更时的输出

环境已预先 apply，进入工作目录先确认三个资源都在：

```
cd /root/workspace
awslocal s3 ls
awslocal dynamodb list-tables
```

此时配置与 state 完全一致，运行 plan 应显示无变更：

```
terraform plan
```

注意末尾的汇总行：

```
No changes. Your infrastructure matches the configuration.
```

## 触发修改（update）：观察 ~ 符号

向 `local.common_tags` 中增加一个新标签，三个资源都共用这个 locals，所以它们都会被标记为变更：

```
sed -i 's/ManagedBy   = "Terraform"/ManagedBy   = "Terraform"\n    Owner       = "platform-team"/' main.tf
```

再次运行 plan，这次会看到变更：

```
terraform plan
```

三个资源行首均显示 ~ 符号，表示将被原地修改（update in place）。

仔细阅读属性变更行：

- 带 + 的行是新增属性
- 带 - 的行是移除属性
- 带 ~ 的行是值发生变化的属性
- (known after apply) 表示该值只有在实际 apply 后才能确定

末尾的汇总行会显示：

```
Plan: 0 to add, 3 to change, 0 to destroy.
```

## 触发重建（replace）：观察 -/+ 与 +/- 符号

S3 的 bucket 名称是不可变属性，修改它会触发先销毁再重建（replace）。先看看直接改名会发生什么：

```
sed -i 's/bucket = "${var.app_name}-${var.environment}-logs-${var.suffix}"/bucket = "${var.app_name}-${var.environment}-logs2-${var.suffix}"/' main.tf
terraform plan
```

在 aws_s3_bucket.logs 资源行前，你会看到 -/+ 符号，以及 forces replacement 的提示：

```
-/+ resource "aws_s3_bucket" "logs" {
```

这是默认的重建顺序：先销毁旧资源，再创建新资源。

现在为 app 桶加上 `create_before_destroy = true`，再观察符号的差异：

```
sed -i '/resource "aws_s3_bucket" "app"/a\  lifecycle {\n    create_before_destroy = true\n  }' main.tf
terraform plan -replace=aws_s3_bucket.app
```

app 桶行前显示的是 +/- 符号：

```
+/- resource "aws_s3_bucket" "app" {
```

plan 输出开头的图例也会同时显示两种符号的含义：

```
-/+ destroy and then create replacement
+/- create replacement and then destroy
```

关键区别：

- -/+ 先销毁后创建，中间有短暂停机窗口
- +/- 先创建后销毁，新资源就绪后才移除旧资源（零停机替换）

汇总行变为：

```
Plan: 2 to add, 0 to change, 2 to destroy.
```

## 恢复配置

将 main.tf 恢复为原始状态，后续步骤继续使用。最简单的方式是直接覆写文件：

```
cat > /root/workspace/main.tf <<'EOTF'
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
    s3       = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
    sts      = "http://localhost:4566"
  }
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "app_name" {
  type    = string
  default = "myapp"
}

variable "suffix" {
  type    = string
  default = "lab"
}

locals {
  common_tags = {
    Environment = var.environment
    App         = var.app_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket" "app" {
  bucket = "${var.app_name}-${var.environment}-app-${var.suffix}"
  tags   = local.common_tags
}

resource "aws_s3_bucket" "logs" {
  bucket = "${var.app_name}-${var.environment}-logs-${var.suffix}"
  tags   = local.common_tags
}

resource "aws_dynamodb_table" "sessions" {
  name         = "${var.app_name}-${var.environment}-sessions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "SessionID"

  attribute {
    name = "SessionID"
    type = "S"
  }

  tags = local.common_tags
}

output "app_bucket" {
  value = aws_s3_bucket.app.bucket
}

output "logs_bucket" {
  value = aws_s3_bucket.logs.bucket
}

output "sessions_table" {
  value = aws_dynamodb_table.sessions.name
}
EOTF
terraform plan
```

确认末尾显示 No changes 后进入下一步。
