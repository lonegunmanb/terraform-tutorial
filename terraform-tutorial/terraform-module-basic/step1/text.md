# 第一步：根模块与标准结构

在这一步中，你将认识 Terraform 的根模块概念，并理解模块的标准文件组织方式。

## 你已经在使用模块了

进入工作目录，查看当前代码：

```bash
cd /root/workspace/step1
cat main.tf
```

这个目录包含 `.tf` 文件，它就是一个 Terraform **根模块**（Root Module）。你在前面所有章节中编写的代码——provider 配置、resource 声明、variable 和 output——都属于根模块的内容。

当你执行 `terraform plan` 或 `terraform apply` 时，Terraform 从当前工作目录加载所有 `.tf` 文件，这个目录就是根模块。

## 执行根模块

```bash
terraform plan
```

观察输出——Terraform 计划创建两个 S3 桶和对应的输出值。这些资源直接定义在根模块中。

```bash
terraform apply -auto-approve
```

验证资源已创建：

```bash
awslocal s3 ls
```

## 查看状态中的资源地址

```bash
terraform state list
```

输出类似：

```
aws_s3_bucket.app_data
aws_s3_bucket.app_logs
```

注意资源地址的格式：`<资源类型>.<名称>`。当我们在下一步引入模块后，地址格式会变为 `module.<模块名>.<资源类型>.<名称>`。

## 重构为标准模块结构

当前所有代码都在一个 main.tf 文件中。在实际项目中，推荐按照**标准模块结构**组织文件——将变量、输出和主逻辑分开：

```bash
# 创建 variables.tf — 输入变量
cat > variables.tf <<'EOF'
variable "data_bucket_name" {
  type        = string
  default     = "my-app-data"
  description = "数据桶的名称"
}

variable "logs_bucket_name" {
  type        = string
  default     = "my-app-logs"
  description = "日志桶的名称"
}
EOF
```

```bash
# 创建 outputs.tf — 输出值
cat > outputs.tf <<'EOF'
output "data_bucket_id" {
  value       = aws_s3_bucket.app_data.id
  description = "数据桶的 ID"
}

output "logs_bucket_id" {
  value       = aws_s3_bucket.app_logs.id
  description = "日志桶的 ID"
}
EOF
```

更新 main.tf，移除 output 块并使用变量引用：

```bash
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

resource "aws_s3_bucket" "app_data" {
  bucket = var.data_bucket_name
}

resource "aws_s3_bucket" "app_logs" {
  bucket = var.logs_bucket_name
}
EOF
```

现在目录结构符合标准模块的组织方式：

```bash
ls *.tf
```

你会看到三个文件：main.tf、variables.tf、outputs.tf —— 这就是标准模块结构。

验证重构没有破坏任何东西：

```bash
terraform plan
```

因为桶名的默认值和之前硬编码的一样，Terraform 应该显示 "No changes"——这说明文件拆分不影响行为，Terraform 会加载目录下所有 .tf 文件。

## 清理

```bash
terraform destroy -auto-approve
```

## 关键点

- 任何包含 .tf 文件的目录都是一个模块
- 执行 terraform 命令时，当前目录就是根模块
- 标准模块结构：main.tf（资源）、variables.tf（输入）、outputs.tf（输出）
- 文件名只是约定，Terraform 会加载目录下所有 .tf 文件

完成后继续下一步。
