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
# Terraform 类型示例：原始类型
# ==============================

# ── string 类型 ──
variable "name" {
  type    = string
  default = "Terraform"
}

# ── number 类型 ──
variable "port" {
  type    = number
  default = 8080
}

variable "pi" {
  type    = number
  default = 3.14159
}

# ── bool 类型 ──
variable "enabled" {
  type    = bool
  default = true
}

# ── 隐式类型转换演示 ──
# number 和 bool 都可以与 string 互相隐式转换
variable "string_number" {
  type    = string
  default = "42"
}

variable "string_bool" {
  type    = string
  default = "true"
}

locals {
  # string → number 的隐式转换
  computed_number = var.string_number + 1
  # => 43（字符串 "42" 自动转换为数字 42）

  # string → bool 的隐式转换
  computed_bool = var.string_bool ? "yes" : "no"
  # => "yes"（字符串 "true" 自动转换为 true）

  # number → string 的隐式转换
  port_label = "Port: ${var.port}"
  # => "Port: 8080"（数字自动转换为字符串）
}

output "name" {
  value = var.name
}

output "port" {
  value = var.port
}

output "pi" {
  value = var.pi
}

output "enabled" {
  value = var.enabled
}

output "computed_number" {
  value = local.computed_number
}

output "computed_bool" {
  value = local.computed_bool
}

output "port_label" {
  value = local.port_label
}
EOTF
fi

if [ ! -f /root/workspace/step2/main.tf ]; then
cat > /root/workspace/step2/main.tf <<'EOTF'
# ==============================
# Terraform 类型示例：集合类型
# ==============================

# ── list 类型 ──
# list 是有序集合，元素类型相同，下标从 0 开始
variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "ports" {
  type    = list(number)
  default = [80, 443, 8080]
}

# ── map 类型 ──
# map 是键值对集合，键一定是 string，值类型相同
variable "tags" {
  type = map(string)
  default = {
    Environment = "dev"
    Team        = "platform"
    Project     = "demo"
  }
}

variable "instance_counts" {
  type = map(number)
  default = {
    web = 3
    api = 2
    db  = 1
  }
}

# ── set 类型 ──
# set 是无序、不重复的集合
variable "allowed_cidrs" {
  type    = set(string)
  default = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

locals {
  # list 用下标访问
  first_zone = var.availability_zones[0]
  # => "us-east-1a"

  # list 长度
  zone_count = length(var.availability_zones)
  # => 3

  # map 用键名访问
  env_tag = var.tags["Environment"]
  # => "dev"

  # map 获取所有键
  tag_keys = keys(var.tags)

  # set 不能用下标访问，但可以用 contains 检查元素
  has_private = contains(var.allowed_cidrs, "10.0.0.0/8")
  # => true

  # list(any) 隐式类型转换：所有元素会被转为同一类型
  mixed_to_string = tolist(["hello", 42, true])
  # => ["hello", "42", "true"]（全部转换为 string）

  # ⚠️ "同一类型"比你想象的更严格！
  # 以下写法看起来像合法的 list 或 map，但会报错：
  #
  #   tolist(["hello", ["a", "b"]])
  #   # ❌ 报错！string 和 list 无法转换为同一类型
  #
  #   tomap({name = "alice", config = { port = 8080 }})
  #   # ❌ 报错！string 和 object 不是同一类型
  #
  # 经验法则：如果不同键需要不同类型的值，用 object 而不是 map
}

output "first_zone" {
  value = local.first_zone
}

output "zone_count" {
  value = local.zone_count
}

output "env_tag" {
  value = local.env_tag
}

output "tag_keys" {
  value = local.tag_keys
}

output "has_private" {
  value = local.has_private
}

output "mixed_to_string" {
  value = local.mixed_to_string
}

output "ports" {
  value = var.ports
}

output "instance_counts" {
  value = var.instance_counts
}
EOTF
fi

if [ ! -f /root/workspace/step3/main.tf ]; then
cat > /root/workspace/step3/main.tf <<'EOTF'
# ==============================
# Terraform 类型示例：结构化类型
# ==============================

# ── object 类型 ──
# object 由一组命名属性组成，每个属性可以有不同的类型
variable "server" {
  type = object({
    name   = string
    port   = number
    active = bool
  })
  default = {
    name   = "web-01"
    port   = 8080
    active = true
  }
}

# ── tuple 类型 ──
# tuple 类似 list，但每个位置可以有不同的类型
variable "record" {
  type    = tuple([string, number, bool])
  default = ["hello", 42, true]
}

# ── object 的 optional 成员（Terraform >= 1.3）──
variable "database" {
  type = object({
    engine  = string
    version = optional(string, "14")
    port    = optional(number, 5432)
    config  = optional(object({
      max_connections = optional(number, 100)
      ssl_enabled     = optional(bool, true)
    }), {})
  })
  default = {
    engine = "postgresql"
  }
}

# ── any 类型约束 ──
variable "flexible" {
  type    = any
  default = "anything goes"
}

# ── null 值 ──
variable "maybe_name" {
  type    = string
  default = null
}

locals {
  # 访问 object 属性
  server_name = var.server.name
  server_port = var.server.port

  # 访问 tuple 元素（下标访问）
  record_name = var.record[0]
  record_num  = var.record[1]

  # optional 属性的默认值生效
  db_version = var.database.version
  db_port    = var.database.port
  db_max_conn = var.database.config.max_connections
  db_ssl      = var.database.config.ssl_enabled

  # null 与默认值
  display_name = var.maybe_name != null ? var.maybe_name : "anonymous"
}

output "server_name" {
  value = local.server_name
}

output "server_port" {
  value = local.server_port
}

output "record_name" {
  value = local.record_name
}

output "record_num" {
  value = local.record_num
}

output "db_version" {
  value = local.db_version
}

output "db_port" {
  value = local.db_port
}

output "db_max_conn" {
  value = local.db_max_conn
}

output "db_ssl" {
  value = local.db_ssl
}

output "display_name" {
  value = local.display_name
}
EOTF
fi

if [ ! -f /root/workspace/step4/exercises.tf ]; then
cat > /root/workspace/step4/exercises.tf <<'EOTF'
# =============================================
# 🧪 类型系统练习
# =============================================
# 完成以下四道练习，然后运行 terraform test 验证答案。
#
# 运行命令：
#   terraform test
#
# 所有测试通过即为完成！
# =============================================


# ── 练习 1：定义一个 list(number) 变量 ──
# 定义一个 variable 块，名称为 "scores"
# 类型为 list(number)
# 默认值为 [90, 85, 72, 95]
#
# 提示：
#   variable "name" {
#     type    = list(number)
#     default = [...]
#   }

# >>> 在此处写入你的代码 <<<


# ── 练习 2：定义一个 map(string) 变量 ──
# 定义一个 variable 块，名称为 "labels"
# 类型为 map(string)
# 默认值包含以下键值对：
#   app  = "web"
#   env  = "prod"
#   team = "backend"
#
# 提示：
#   variable "name" {
#     type = map(string)
#     default = {
#       key = "value"
#     }
#   }

# >>> 在此处写入你的代码 <<<


# ── 练习 3：定义一个带 optional 属性的 object 变量 ──
# 定义一个 variable 块，名称为 "app_config"
# 类型为 object，包含以下属性：
#   name     = string                    （必填）
#   replicas = optional(number, 1)       （可选，默认 1）
#   debug    = optional(bool, false)     （可选，默认 false）
#
# 默认值只设置 name = "my-app"
#
# 提示：
#   variable "name" {
#     type = object({
#       attr1 = string
#       attr2 = optional(type, default_value)
#     })
#     default = { ... }
#   }

# >>> 在此处写入你的代码 <<<


# ── 练习 4：使用集合函数和类型转换 ──
# 定义一个 locals 块，包含以下值：
#
#   highest_score = max(var.scores...)
#   （使用 max() 函数求 var.scores 中的最大值，
#    注意要用 ... 展开 list）
#
#   app_label = "${var.labels["app"]}-${var.labels["env"]}"
#   （使用字符串插值拼接 labels 的 app 和 env）
#
#   replica_count = var.app_config.replicas
#   （读取 app_config 的 replicas 属性，验证 optional 默认值）
#
# 提示：max(list...) 展开 list 作为参数

# >>> 在此处写入你的代码 <<<
EOTF
fi

if [ ! -f /root/workspace/step4/outputs.tf ]; then
cat > /root/workspace/step4/outputs.tf <<'EOTF'
# 此文件用于测试验证，请勿修改

output "check_scores" {
  value = var.scores
}

output "check_labels" {
  value = var.labels
}

output "check_app_config" {
  value = var.app_config
}

output "check_highest_score" {
  value = local.highest_score
}

output "check_app_label" {
  value = local.app_label
}

output "check_replica_count" {
  value = local.replica_count
}
EOTF
fi

if [ ! -f /root/workspace/step4/tests/exercises.tftest.hcl ]; then
cat > /root/workspace/step4/tests/exercises.tftest.hcl <<'EOTF'
run "check_list_variable" {
  command = plan

  assert {
    condition     = length(output.check_scores) == 4
    error_message = "练习 1 未通过：var.scores 应包含 4 个元素"
  }

  assert {
    condition     = output.check_scores[0] == 90
    error_message = "练习 1 未通过：var.scores 的第一个元素应为 90"
  }

  assert {
    condition     = output.check_scores[3] == 95
    error_message = "练习 1 未通过：var.scores 的最后一个元素应为 95"
  }
}

run "check_map_variable" {
  command = plan

  assert {
    condition     = output.check_labels["app"] == "web"
    error_message = "练习 2 未通过：var.labels[\"app\"] 应为 \"web\""
  }

  assert {
    condition     = output.check_labels["env"] == "prod"
    error_message = "练习 2 未通过：var.labels[\"env\"] 应为 \"prod\""
  }

  assert {
    condition     = output.check_labels["team"] == "backend"
    error_message = "练习 2 未通过：var.labels[\"team\"] 应为 \"backend\""
  }
}

run "check_object_optional" {
  command = plan

  assert {
    condition     = output.check_app_config.name == "my-app"
    error_message = "练习 3 未通过：var.app_config.name 应为 \"my-app\""
  }

  assert {
    condition     = output.check_app_config.replicas == 1
    error_message = "练习 3 未通过：var.app_config.replicas 的默认值应为 1"
  }

  assert {
    condition     = output.check_app_config.debug == false
    error_message = "练习 3 未通过：var.app_config.debug 的默认值应为 false"
  }
}

run "check_expressions" {
  command = plan

  assert {
    condition     = output.check_highest_score == 95
    error_message = "练习 4 未通过：local.highest_score 应为 95（使用 max(var.scores...)）"
  }

  assert {
    condition     = output.check_app_label == "web-prod"
    error_message = "练习 4 未通过：local.app_label 应为 \"web-prod\""
  }

  assert {
    condition     = output.check_replica_count == 1
    error_message = "练习 4 未通过：local.replica_count 应为 1（optional 默认值）"
  }
}
EOTF
fi

# ── 3. Install Terraform ──
install_terraform

# ── 4. Pre-init all step directories ──
for dir in /root/workspace/step1 /root/workspace/step2 /root/workspace/step3 /root/workspace/step4; do
  cd "$dir"
  terraform init -input=false
done

finish_setup
