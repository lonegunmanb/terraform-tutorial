#!/bin/bash
exec > /tmp/background.log 2>&1
set -x

source /root/setup-common.sh

# ── 1. Ensure workspace directories exist ──
mkdir -p /root/workspace/step1
mkdir -p /root/workspace/step2
mkdir -p /root/workspace/step3
mkdir -p /root/workspace/step4/tests

# ── 2. Seed workspace files (fallback if assets copy fails) ──

if [ ! -f /root/workspace/step1/main.tf ]; then
cat > /root/workspace/step1/main.tf <<'EOTF'
# ==============================
# Terraform 输入变量：基础用法
# ==============================

# ── string 类型变量 ──
variable "project" {
  type        = string
  default     = "my-app"
  description = "项目名称"
}

# ── number 类型变量 ──
variable "port" {
  type        = number
  default     = 8080
  description = "应用端口号"
}

# ── bool 类型变量 ──
variable "enabled" {
  type        = bool
  default     = true
  description = "是否启用服务"
}

# ── 复合类型变量 ──
variable "tags" {
  type = map(string)
  default = {
    Environment = "dev"
    Team        = "platform"
  }
  description = "资源标签"
}

# ── 有默认值的变量 ──
variable "owner" {
  type        = string
  default     = "terraform-user"
  description = "资源所有者（有默认值，不会提示输入）"
}

# ── 通过 var.<NAME> 引用变量 ──
locals {
  greeting    = "Project: ${var.project}"
  port_string = "Port is ${var.port}"
  status      = var.enabled ? "enabled" : "disabled"
  full_label  = "${var.project}-${var.tags["Environment"]}"
}

output "project" {
  value = var.project
}

output "port" {
  value = var.port
}

output "enabled" {
  value = var.enabled
}

output "tags" {
  value = var.tags
}

output "owner" {
  value = var.owner
}

output "greeting" {
  value = local.greeting
}

output "port_string" {
  value = local.port_string
}

output "status" {
  value = local.status
}

output "full_label" {
  value = local.full_label
}
EOTF
fi

if [ ! -f /root/workspace/step2/main.tf ]; then
cat > /root/workspace/step2/main.tf <<'EOTF'
# ==============================
# Terraform 输入变量：断言校验
# ==============================

# ── 简单条件校验 ──
variable "instance_count" {
  type        = number
  default     = 3
  description = "实例数量，必须在 1-10 之间"

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "instance_count 必须在 1 到 10 之间。"
  }
}

# ── 使用 can + regex 校验格式 ──
variable "image_id" {
  type        = string
  default     = "ami-abc12345"
  description = "机器镜像 ID，必须以 ami- 开头"

  validation {
    condition     = can(regex("^ami-", var.image_id))
    error_message = "image_id 必须以 \"ami-\" 开头。"
  }
}

# ── 使用 contains 校验枚举值 ──
variable "environment" {
  type        = string
  default     = "dev"
  description = "部署环境，仅允许 dev、staging、prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment 必须是 dev、staging 或 prod 之一。"
  }
}

# ── 多重校验（一个变量多个 validation 块）──
variable "bucket_name" {
  type        = string
  default     = "my-demo-bucket"
  description = "S3 存储桶名称"

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "bucket_name 长度必须在 3-63 个字符之间。"
  }

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.bucket_name))
    error_message = "bucket_name 只能包含小写字母、数字、点和连字符，且必须以字母或数字开头和结尾。"
  }
}

locals {
  summary     = "环境: ${var.environment}, 实例: ${var.instance_count}, 镜像: ${var.image_id}, 桶: ${var.bucket_name}"
  count_range = "${var.min_count} ~ ${var.max_count}"
}

# ── 跨变量引用校验（Terraform >= 1.9）──
variable "min_count" {
  type        = number
  default     = 1
  description = "最小实例数"
}

variable "max_count" {
  type        = number
  default     = 10
  description = "最大实例数，必须 >= min_count"

  validation {
    condition     = var.max_count >= var.min_count
    error_message = "max_count（${var.max_count}）不能小于 min_count（${var.min_count}）。"
  }
}

output "instance_count" {
  value = var.instance_count
}

output "image_id" {
  value = var.image_id
}

output "environment" {
  value = var.environment
}

output "bucket_name" {
  value = var.bucket_name
}

output "min_count" {
  value = var.min_count
}

output "max_count" {
  value = var.max_count
}

output "count_range" {
  value = local.count_range
}

output "summary" {
  value = local.summary
}
EOTF
fi

if [ ! -f /root/workspace/step3/main.tf ]; then
cat > /root/workspace/step3/main.tf <<'EOTF'
# ==============================
# Terraform 输入变量：敏感值与赋值
# ==============================

# ── sensitive 变量 ──
variable "db_password" {
  type        = string
  default     = "super-secret-123"
  sensitive   = true
  description = "数据库密码（敏感值，plan/apply 输出中会被隐藏）"
}

# ── nullable = false ──
variable "region" {
  type        = string
  default     = "us-east-1"
  nullable    = false
  description = "部署区域，不允许为 null"
}

# ── 用于演示赋值方式的变量 ──
variable "app_name" {
  type        = string
  default     = "default-app"
  description = "应用名称（可通过 -var、.tfvars 或环境变量赋值）"
}

variable "replica_count" {
  type        = number
  default     = 1
  description = "副本数量"
}

# ── ephemeral 临时变量（Terraform >= 1.10）──
variable "session_token" {
  type        = string
  default     = "tok-temp-abc123"
  ephemeral   = true
  description = "临时会话令牌（不会记录到状态文件和计划文件中）"
}

locals {
  deployment_label = "${var.app_name}-${var.region}-x${var.replica_count}"
  # ephemeral 变量可以在 locals 中引用
  auth_header      = "Bearer ${var.session_token}"
}

output "db_password" {
  value     = var.db_password
  sensitive = true
}

output "region" {
  value = var.region
}

output "app_name" {
  value = var.app_name
}

output "replica_count" {
  value = var.replica_count
}

output "deployment_label" {
  value = local.deployment_label
}

output "auth_header" {
  value     = local.auth_header
  ephemeral = true
}
EOTF
fi

if [ ! -f /root/workspace/step3/dev.tfvars ]; then
cat > /root/workspace/step3/dev.tfvars <<'EOTF'
app_name      = "web-frontend"
replica_count = 5
EOTF
fi

if [ ! -f /root/workspace/step4/exercises.tf ]; then
cat > /root/workspace/step4/exercises.tf <<'EOTF'
# =============================================
# 🧪 输入变量综合练习：创建 EC2 实例
# =============================================
# 综合运用 variable 的类型约束、validation、sensitive，
# 用变量驱动创建一个真实的 EC2 实例。
# 完成后运行 terraform test 验证答案。
#
# 运行命令：
#   terraform test
#
# 所有测试通过即为完成！
# =============================================


# ── 练习 1：定义实例名称变量（带 validation）──
# 定义一个 variable 块，名称为 "instance_name"
# 类型为 string
# 默认值为 "my-tutorial-vm"
# 添加 validation 块：名称长度必须在 3 到 30 个字符之间
# error_message 为 "instance_name 长度必须在 3-30 个字符之间。"
#
# 提示：使用 length() 函数获取字符串长度

# >>> 在此处写入你的代码 <<<


# ── 练习 2：定义实例类型变量（带枚举校验）──
# 定义一个 variable 块，名称为 "instance_type"
# 类型为 string
# 默认值为 "t2.micro"
# 添加 validation 块：只允许 "t2.micro"、"t2.small"、"t2.medium"
# error_message 为 "instance_type 必须是 t2.micro、t2.small 或 t2.medium 之一。"
#
# 提示：使用 contains() 函数检查值是否在列表中

# >>> 在此处写入你的代码 <<<


# ── 练习 3：定义 sensitive 的标签变量 ──
# 定义一个 variable 块，名称为 "owner"
# 类型为 string
# 默认值为 "ops-team"
# 设置 sensitive = true
#
# 这个变量将用在实例的 tags 中，观察 sensitive 如何影响 plan 输出。

# >>> 在此处写入你的代码 <<<


# ── 练习 4：用变量创建 EC2 实例 ──
# 创建一个 aws_instance 资源，名称为 "exercise"
# - ami 使用 "ami-0c55b159cbfafe1f0"
# - instance_type 使用 var.instance_type
# - tags 包含：
#     Name  = var.instance_name
#     Owner = var.owner
#
# 提示：
#   resource "aws_instance" "exercise" {
#     ami           = "..."
#     instance_type = var.instance_type
#     tags = {
#       Name  = var.instance_name
#       Owner = var.owner
#     }
#   }

# >>> 在此处写入你的代码 <<<
EOTF
fi

if [ ! -f /root/workspace/step4/outputs.tf ]; then
cat > /root/workspace/step4/outputs.tf <<'EOTF'
# 此文件用于测试验证，请勿修改

output "check_instance_id" {
  value = aws_instance.exercise.id
}

output "check_instance_type" {
  value = aws_instance.exercise.instance_type
}

output "check_instance_name" {
  value = var.instance_name
}

output "check_owner" {
  value     = var.owner
  sensitive = true
}
EOTF
fi

if [ ! -f /root/workspace/step4/provider.tf ]; then
cat > /root/workspace/step4/provider.tf <<'EOTF'
# 此文件用于配置 AWS Provider 连接 LocalStack，请勿修改

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
    ec2 = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}
EOTF
fi

if [ ! -f /root/workspace/step4/docker-compose.yml ]; then
cat > /root/workspace/step4/docker-compose.yml <<'EOTF'
services:
  localstack:
    image: localstack/localstack:3
    ports:
      - "4566:4566"
    environment:
      - SERVICES=ec2
      - DEFAULT_REGION=us-east-1
      - EAGER_SERVICE_LOADING=1
    deploy:
      resources:
        limits:
          memory: 1536M
EOTF
fi

if [ ! -f /root/workspace/step4/tests/exercises.tftest.hcl ]; then
mkdir -p /root/workspace/step4/tests
cat > /root/workspace/step4/tests/exercises.tftest.hcl <<'EOTF'
run "create_instance_with_defaults" {
  command = apply

  assert {
    condition     = output.check_instance_id != ""
    error_message = "练习 4 未通过：EC2 实例未成功创建（instance_id 为空）"
  }

  assert {
    condition     = output.check_instance_type == "t2.micro"
    error_message = "练习 2/4 未通过：instance_type 应为 \"t2.micro\""
  }

  assert {
    condition     = output.check_instance_name == "my-tutorial-vm"
    error_message = "练习 1 未通过：var.instance_name 的默认值应为 \"my-tutorial-vm\""
  }

  assert {
    condition     = nonsensitive(output.check_owner) == "ops-team"
    error_message = "练习 3 未通过：var.owner 的默认值应为 \"ops-team\""
  }
}

run "validate_instance_name_length" {
  command = plan

  variables {
    instance_name = "ab"
  }

  expect_failures = [
    var.instance_name,
  ]
}

run "validate_instance_type_enum" {
  command = plan

  variables {
    instance_type = "t2.xlarge"
  }

  expect_failures = [
    var.instance_type,
  ]
}

run "create_instance_with_custom_vars" {
  command = apply

  variables {
    instance_name = "custom-server"
    instance_type = "t2.small"
    owner         = "dev-team"
  }

  assert {
    condition     = output.check_instance_id != ""
    error_message = "自定义变量创建实例失败"
  }

  assert {
    condition     = output.check_instance_type == "t2.small"
    error_message = "instance_type 应为传入的 \"t2.small\""
  }

  assert {
    condition     = output.check_instance_name == "custom-server"
    error_message = "instance_name 应为传入的 \"custom-server\""
  }

  assert {
    condition     = nonsensitive(output.check_owner) == "dev-team"
    error_message = "owner 应为传入的 \"dev-team\""
  }
}
EOTF
fi

# ── 3. Install Terraform ──
install_terraform

# ── 4. Start LocalStack for step4 ──
cd /root/workspace/step4
start_localstack

# ── 5. Pre-init all step directories ──
for dir in /root/workspace/step1 /root/workspace/step2 /root/workspace/step3 /root/workspace/step4; do
  cd "$dir"
  terraform init -input=false
done

finish_setup
