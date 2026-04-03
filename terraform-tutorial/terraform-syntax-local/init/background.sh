#!/bin/bash
exec > /tmp/background.log 2>&1
set -x

source /root/setup-common.sh

# ── 1. Ensure workspace directories exist ──
mkdir -p /root/workspace/step1
mkdir -p /root/workspace/step2/tests

# ── 2. Seed workspace files (fallback if assets copy fails) ──

if [ ! -f /root/workspace/step1/main.tf ]; then
cat > /root/workspace/step1/main.tf <<'EOTF'
# ==============================
# Terraform 局部值示例
# ==============================

# ── 1. 定义局部值 ──
locals {
  project     = "my-app"
  environment = "dev"
  region      = "us-east-1"
}

# 可以定义多个 locals 块，按逻辑分组
locals {
  # 引用其他局部值
  full_name = "${local.project}-${local.environment}"

  # 使用条件表达式
  is_prod = local.environment == "prod"
}

output "basic" {
  value = {
    project     = local.project
    environment = local.environment
    region      = local.region
    full_name   = local.full_name
    is_prod     = local.is_prod
  }
}

# ── 2. 局部值可以是各种类型 ──
locals {
  # 字符串
  greeting = "Hello, ${local.project}!"

  # 数字
  max_instances = 3

  # 布尔值
  enable_logging = true

  # 列表
  availability_zones = ["${local.region}a", "${local.region}b", "${local.region}c"]

  # Map
  base_tags = {
    Project     = local.project
    Environment = local.environment
    ManagedBy   = "terraform"
  }
}

output "types" {
  value = {
    greeting           = local.greeting
    max_instances      = local.max_instances
    enable_logging     = local.enable_logging
    availability_zones = local.availability_zones
    base_tags          = local.base_tags
  }
}

# ── 3. 避免重复：合并标签 ──
variable "extra_tags" {
  type = map(string)
  default = {
    Owner = "team-platform"
  }
}

locals {
  # merge 将多个 map 合并为一个，定义一次、多处引用
  common_tags = merge(local.base_tags, var.extra_tags)
}

output "common_tags" {
  value = local.common_tags
}

# ── 4. 命名复杂表达式 ──
locals {
  is_production = local.environment == "prod"
  log_level     = local.is_production ? "warn" : "debug"
  instance_type = local.is_production ? "m5.large" : "t3.micro"
}

output "named_expressions" {
  value = {
    is_production = local.is_production
    log_level     = local.log_level
    instance_type = local.instance_type
  }
}

# ── 5. 预处理输入数据 ──
variable "raw_cidrs" {
  type    = list(string)
  default = ["10.0.0.0/8", " 172.16.0.0/12 ", "  192.168.0.0/16  "]
}

locals {
  # 去除每个 CIDR 的前后空格
  clean_cidrs = [for cidr in var.raw_cidrs : trimspace(cidr)]

  # 构建 key=value 格式的标签字符串
  tag_strings = [for k, v in local.common_tags : "${k}=${v}"]
}

output "preprocessed" {
  value = {
    clean_cidrs = local.clean_cidrs
    tag_strings = local.tag_strings
  }
}

# ── 6. 链式引用 ──
locals {
  base_name   = "${local.project}-${local.environment}"
  bucket_name = "${local.base_name}-data"
  log_bucket  = "${local.base_name}-logs"
}

output "chained" {
  value = {
    base_name   = local.base_name
    bucket_name = local.bucket_name
    log_bucket  = local.log_bucket
  }
}
EOTF
fi

if [ ! -f /root/workspace/step2/exercises.tf ]; then
cat > /root/workspace/step2/exercises.tf <<'EOTF'
# =============================================
# 🧪 局部值练习
# =============================================
# 完成以下四道练习，然后运行 terraform test 验证答案。
#
# 运行命令：
#   terraform test
#
# 所有测试通过即为完成！
# =============================================


# ── 练习 1：基础局部值 ──
# 在 locals 块中定义两个局部值：
#   - app_name，值为 "web-server"
#   - app_port，值为 8080
#
# 提示：locals { name = value }

# >>> 在此处写入你的代码 <<<


# ── 练习 2：引用与计算 ──
# 给定以下变量（已定义好，请勿修改）：
variable "env" {
  type    = string
  default = "staging"
}
# 在 locals 块中定义：
#   - full_name：值为 app_name 和 env 用 "-" 连接，如 "web-server-staging"
#     提示：使用字符串插值 "${local.app_name}-${var.env}"
#   - is_production：当 env 等于 "prod" 时为 true，否则为 false

# >>> 在此处写入你的代码 <<<


# ── 练习 3：复杂表达式 ──
# 给定以下变量（已定义好，请勿修改）：
variable "users" {
  type    = list(string)
  default = ["alice", "bob", "charlie"]
}
# 在 locals 块中定义：
#   - user_count：用户数量（提示：使用 length 函数）
#   - upper_users：将所有用户名转为大写的列表
#     提示：[for u in var.users : upper(u)]
#   - user_tags：以用户名为键、"active" 为值的 map
#     提示：{for u in var.users : u => "active"}

# >>> 在此处写入你的代码 <<<


# ── 练习 4：标签合并 ──
# 给定以下变量（已定义好，请勿修改）：
variable "custom_tags" {
  type = map(string)
  default = {
    Team = "platform"
  }
}
# 在 locals 块中定义 merged_tags：
#   将以下默认标签与 var.custom_tags 合并
#   默认标签为：{ App = local.app_name, Env = var.env }
#   提示：使用 merge(map1, map2) 函数
#   期望结果：{ App = "web-server", Env = "staging", Team = "platform" }

# >>> 在此处写入你的代码 <<<
EOTF
fi

if [ ! -f /root/workspace/step2/outputs.tf ]; then
cat > /root/workspace/step2/outputs.tf <<'EOTF'
# 此文件用于测试验证，请勿修改

output "check_app_name" {
  value = local.app_name
}

output "check_app_port" {
  value = local.app_port
}

output "check_full_name" {
  value = local.full_name
}

output "check_is_production" {
  value = local.is_production
}

output "check_user_count" {
  value = local.user_count
}

output "check_upper_users" {
  value = local.upper_users
}

output "check_user_tags" {
  value = local.user_tags
}

output "check_merged_tags" {
  value = local.merged_tags
}
EOTF
fi

if [ ! -f /root/workspace/step2/tests/exercises.tftest.hcl ]; then
cat > /root/workspace/step2/tests/exercises.tftest.hcl <<'EOTF'
run "check_basic_locals" {
  command = plan

  assert {
    condition     = output.check_app_name == "web-server"
    error_message = "练习 1 未通过：app_name 应为 \"web-server\""
  }

  assert {
    condition     = output.check_app_port == 8080
    error_message = "练习 1 未通过：app_port 应为 8080"
  }
}

run "check_reference" {
  command = plan

  assert {
    condition     = output.check_full_name == "web-server-staging"
    error_message = "练习 2 未通过：full_name 应为 \"web-server-staging\"（app_name + \"-\" + env）"
  }

  assert {
    condition     = output.check_is_production == false
    error_message = "练习 2 未通过：env 为 \"staging\" 时，is_production 应为 false"
  }
}

run "check_complex" {
  command = plan

  assert {
    condition     = output.check_user_count == 3
    error_message = "练习 3 未通过：user_count 应为 3"
  }

  assert {
    condition     = output.check_upper_users[0] == "ALICE"
    error_message = "练习 3 未通过：upper_users 的第一个元素应为 \"ALICE\""
  }

  assert {
    condition     = output.check_upper_users[2] == "CHARLIE"
    error_message = "练习 3 未通过：upper_users 的第三个元素应为 \"CHARLIE\""
  }

  assert {
    condition     = output.check_user_tags["alice"] == "active"
    error_message = "练习 3 未通过：user_tags[\"alice\"] 应为 \"active\""
  }
}

run "check_merge" {
  command = plan

  assert {
    condition     = output.check_merged_tags["App"] == "web-server"
    error_message = "练习 4 未通过：merged_tags[\"App\"] 应为 \"web-server\""
  }

  assert {
    condition     = output.check_merged_tags["Env"] == "staging"
    error_message = "练习 4 未通过：merged_tags[\"Env\"] 应为 \"staging\""
  }

  assert {
    condition     = output.check_merged_tags["Team"] == "platform"
    error_message = "练习 4 未通过：merged_tags[\"Team\"] 应为 \"platform\"（来自 var.custom_tags）"
  }
}
EOTF
fi

# ── 3. Install Terraform ──
install_terraform

# ── 4. Signal ready ──
finish_setup
