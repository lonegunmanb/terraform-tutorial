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
# Terraform 表达式示例：运算符与条件表达式
# ==============================

# ── 算术运算符 ──
locals {
  a = 10
  b = 3

  sum       = local.a + local.b    # 13
  diff      = local.a - local.b    # 7
  product   = local.a * local.b    # 30
  quotient  = local.a / local.b    # 3.333...
  remainder = local.a % local.b    # 1
  negative  = -local.a             # -10
}

output "arithmetic" {
  value = {
    sum       = local.sum
    diff      = local.diff
    product   = local.product
    quotient  = local.quotient
    remainder = local.remainder
    negative  = local.negative
  }
}

# ── 比较与相等性运算符 ──
locals {
  x = 5
  y = 10

  is_equal     = local.x == local.y   # false
  is_not_equal = local.x != local.y   # true
  is_less      = local.x < local.y    # true
  is_greater   = local.x > local.y    # false
  is_lte       = local.x <= 5         # true
  is_gte       = local.y >= 10        # true
}

output "comparison" {
  value = {
    is_equal     = local.is_equal
    is_not_equal = local.is_not_equal
    is_less      = local.is_less
    is_greater   = local.is_greater
  }
}

# ── 逻辑运算符 ──
locals {
  is_prod    = true
  has_budget = false

  # && (与): 两者都为 true 才为 true
  can_deploy = local.is_prod && local.has_budget  # false

  # || (或): 至少一个为 true 即为 true
  needs_review = local.is_prod || local.has_budget  # true

  # ! (非): 取反
  is_not_prod = !local.is_prod  # false
}

output "logic" {
  value = {
    can_deploy   = local.can_deploy
    needs_review = local.needs_review
    is_not_prod  = local.is_not_prod
  }
}

# ── 条件表达式 ──
variable "environment" {
  type    = string
  default = "dev"
}

locals {
  # condition ? true_val : false_val
  instance_type = var.environment == "prod" ? "m5.large" : "t3.micro"
  log_level     = var.environment != "prod" ? "debug" : "warn"

  # 条件表达式结合 null 实现可选赋值
  enable_debug = var.environment == "dev" ? true : null
}

output "conditional" {
  value = {
    instance_type = local.instance_type
    log_level     = local.log_level
    enable_debug  = local.enable_debug
  }
}

# ── 运算符优先级 ──
locals {
  # 乘法优先于加法: 1 + 2 * 3 = 7，不是 9
  priority_demo = 1 + 2 * 3

  # 用小括号改变优先级: (1 + 2) * 3 = 9
  with_parens = (1 + 2) * 3
}

output "priority" {
  value = {
    without_parens = local.priority_demo
    with_parens    = local.with_parens
  }
}
EOTF
fi

if [ ! -f /root/workspace/step2/main.tf ]; then
cat > /root/workspace/step2/main.tf <<'EOTF'
# ==============================
# Terraform 表达式示例：字符串模板与函数调用
# ==============================

variable "name" {
  type    = string
  default = "Terraform"
}

variable "ip_list" {
  type    = list(string)
  default = ["10.0.1.1", "10.0.1.2", "10.0.1.3"]
}

# ── 字符串插值 ──
locals {
  greeting = "Hello, ${var.name}!"
  # => "Hello, Terraform!"

  # 转义：输出字面量 ${}
  literal = "这不是插值：$${not_a_ref}"
}

output "interpolation" {
  value = {
    greeting = local.greeting
    literal  = local.literal
  }
}

# ── 字符串指令：if/else/endif ──
variable "show_name" {
  type    = bool
  default = true
}

locals {
  welcome = "Welcome, %{ if var.show_name }${var.name}%{ else }guest%{ endif }!"
}

output "directive_if" {
  value = local.welcome
  # => "Welcome, Terraform!"
}

# ── 字符串指令：for/endfor ──
locals {
  # 使用 Heredoc + for 指令生成多行配置
  server_list = <<-EOT
  %{ for ip in var.ip_list ~}
  server ${ip}
  %{ endfor ~}
  EOT
}

output "directive_for" {
  value = local.server_list
}

# ── 内建函数 ──
locals {
  # 字符串函数
  upper_name = upper(var.name)                    # "TERRAFORM"
  lower_name = lower(var.name)                    # "terraform"
  name_len   = length(var.name)                   # 9
  joined     = join(", ", var.ip_list)             # "10.0.1.1, 10.0.1.2, 10.0.1.3"
  replaced   = replace("hello world", "world", "terraform")  # "hello terraform"

  # 数值函数
  min_val = min(10, 5, 20, 3)   # 3
  max_val = max(10, 5, 20, 3)   # 20
  abs_val = abs(-42)             # 42

  # 集合函数
  ip_count  = length(var.ip_list)                  # 3
  has_ip    = contains(var.ip_list, "10.0.1.2")    # true
  sorted    = sort(["banana", "apple", "cherry"])   # ["apple", "banana", "cherry"]
  flat_list = flatten([["a", "b"], ["c"]])          # ["a", "b", "c"]

  # 类型转换函数
  num_str  = tostring(42)        # "42"
  str_num  = tonumber("3.14")    # 3.14
  str_bool = tobool("true")      # true

  # 展开符：把列表展开为函数参数
  numbers       = [55, 2453, 2]
  min_from_list = min(local.numbers...)  # 2

  # 编码函数
  json_data = jsonencode({
    name = var.name
    ips  = var.ip_list
  })
}

output "functions" {
  value = {
    upper_name    = local.upper_name
    lower_name    = local.lower_name
    joined        = local.joined
    min_val       = local.min_val
    max_val       = local.max_val
    ip_count      = local.ip_count
    has_ip        = local.has_ip
    min_from_list = local.min_from_list
    json_data     = local.json_data
  }
}
EOTF
fi

if [ ! -f /root/workspace/step3/main.tf ]; then
cat > /root/workspace/step3/main.tf <<'EOTF'
# ==============================
# Terraform 表达式示例：for 表达式与 splat
# ==============================

variable "names" {
  type    = list(string)
  default = ["alice", "bob", "charlie", ""]
}

variable "servers" {
  type = list(object({
    name = string
    port = number
  }))
  default = [
    { name = "web",  port = 80 },
    { name = "api",  port = 8080 },
    { name = "db",   port = 5432 },
  ]
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "dev"
    Team        = "platform"
    Project     = "demo"
  }
}

# ── for 表达式：输出元组 ──
locals {
  # 将所有名字转为大写
  upper_names = [for s in var.names : upper(s)]
  # => ["ALICE", "BOB", "CHARLIE", ""]
}

output "for_tuple" {
  value = local.upper_names
}

# ── for 表达式：带 if 过滤 ──
locals {
  # 过滤掉空字符串
  valid_names = [for s in var.names : upper(s) if s != ""]
  # => ["ALICE", "BOB", "CHARLIE"]
}

output "for_filtered" {
  value = local.valid_names
}

# ── for 表达式：输出对象 ──
locals {
  # 构建 name => uppercase_name 的映射
  name_map = { for s in var.names : s => upper(s) if s != "" }
  # => { "alice" = "ALICE", "bob" = "BOB", "charlie" = "CHARLIE" }
}

output "for_object" {
  value = local.name_map
}

# ── for 表达式：遍历 map ──
locals {
  # 遍历 map，将键值对拼成 "key=value" 列表
  tag_strings = [for k, v in var.tags : "${k}=${v}"]
  # => ["Environment=dev", "Project=demo", "Team=platform"]
}

output "for_map" {
  value = local.tag_strings
}

# ── for 表达式：分组 (group by) ──
locals {
  fruits = ["apple", "avocado", "banana", "blueberry", "cherry"]

  # 按首字母分组，使用 ... 聚合同键的值为列表
  grouped = { for s in local.fruits : substr(s, 0, 1) => s... }
  # => { "a" = ["apple", "avocado"], "b" = ["banana", "blueberry"], "c" = ["cherry"] }
}

output "for_grouped" {
  value = local.grouped
}

# ── splat 表达式 ──
locals {
  # 等价于 [for s in var.servers : s.name]
  server_names = var.servers[*].name
  # => ["web", "api", "db"]

  # 等价于 [for s in var.servers : s.port]
  server_ports = var.servers[*].port
  # => [80, 8080, 5432]
}

output "splat" {
  value = {
    names = local.server_names
    ports = local.server_ports
  }
}

# ── 综合示例：for + 条件 + 函数 ──
locals {
  # 找出端口号大于 1000 的服务器，生成 "NAME:PORT" 格式
  high_port_servers = [
    for s in var.servers : "${upper(s.name)}:${s.port}"
    if s.port > 1000
  ]
  # => ["API:8080", "DB:5432"]
}

output "combined" {
  value = local.high_port_servers
}
EOTF
fi

if [ ! -f /root/workspace/step4/exercises.tf ]; then
cat > /root/workspace/step4/exercises.tf <<'EOTF'
# =============================================
# 🧪 表达式练习
# =============================================
# 完成以下四道练习，然后运行 terraform test 验证答案。
#
# 运行命令：
#   terraform test
#
# 所有测试通过即为完成！
# =============================================


# ── 练习 1：条件表达式 ──
# 定义一个 variable "score"，类型为 number，默认值为 85
# 然后在 locals 块中定义 grade，使用条件表达式：
#   - score >= 60 时为 "pass"
#   - 否则为 "fail"
#
# 提示：
#   condition ? true_val : false_val

# >>> 在此处写入你的代码 <<<


# ── 练习 2：for 表达式（过滤与转换） ──
# 给定以下变量（已定义好，请勿修改）：
variable "words" {
  type    = list(string)
  default = ["hello", "", "world", "", "terraform"]
}
# 在 locals 块中定义 clean_words：
#   1. 过滤掉空字符串
#   2. 将剩余元素转为大写
# 期望结果：["HELLO", "WORLD", "TERRAFORM"]

# >>> 在此处写入你的代码 <<<


# ── 练习 3：for 表达式（生成 map） ──
# 给定以下变量（已定义好，请勿修改）：
variable "users" {
  type = list(object({
    name = string
    role = string
  }))
  default = [
    { name = "alice", role = "admin" },
    { name = "bob",   role = "dev" },
    { name = "carol", role = "admin" },
  ]
}
# 在 locals 块中定义 user_roles：
#   使用 for 表达式生成 map，键为 name，值为 role
# 期望结果：{ "alice" = "admin", "bob" = "dev", "carol" = "admin" }

# >>> 在此处写入你的代码 <<<


# ── 练习 4：splat 表达式 ──
# 使用上面已定义的 var.users
# 在 locals 块中定义 user_names：
#   使用 splat 表达式 [*] 提取所有用户的 name 属性
# 期望结果：["alice", "bob", "carol"]

# >>> 在此处写入你的代码 <<<
EOTF
fi

if [ ! -f /root/workspace/step4/outputs.tf ]; then
cat > /root/workspace/step4/outputs.tf <<'EOTF'
# 此文件用于测试验证，请勿修改

output "check_grade" {
  value = local.grade
}

output "check_clean_words" {
  value = local.clean_words
}

output "check_user_roles" {
  value = local.user_roles
}

output "check_user_names" {
  value = local.user_names
}
EOTF
fi

if [ ! -f /root/workspace/step4/tests/exercises.tftest.hcl ]; then
cat > /root/workspace/step4/tests/exercises.tftest.hcl <<'EOTF'
run "check_conditional" {
  command = plan

  assert {
    condition     = output.check_grade == "pass"
    error_message = "练习 1 未通过：score 为 85 时，grade 应为 \"pass\""
  }
}

run "check_for_filter" {
  command = plan

  assert {
    condition     = length(output.check_clean_words) == 3
    error_message = "练习 2 未通过：clean_words 应有 3 个元素（过滤掉空字符串）"
  }

  assert {
    condition     = output.check_clean_words[0] == "HELLO"
    error_message = "练习 2 未通过：第一个元素应为 \"HELLO\"（转为大写）"
  }

  assert {
    condition     = output.check_clean_words[2] == "TERRAFORM"
    error_message = "练习 2 未通过：第三个元素应为 \"TERRAFORM\""
  }
}

run "check_for_map" {
  command = plan

  assert {
    condition     = output.check_user_roles["alice"] == "admin"
    error_message = "练习 3 未通过：user_roles[\"alice\"] 应为 \"admin\""
  }

  assert {
    condition     = output.check_user_roles["bob"] == "dev"
    error_message = "练习 3 未通过：user_roles[\"bob\"] 应为 \"dev\""
  }
}

run "check_splat" {
  command = plan

  assert {
    condition     = length(output.check_user_names) == 3
    error_message = "练习 4 未通过：user_names 应有 3 个元素"
  }

  assert {
    condition     = output.check_user_names[0] == "alice"
    error_message = "练习 4 未通过：第一个元素应为 \"alice\"（使用 splat 表达式）"
  }
}
EOTF
fi

# ── 3. Install Terraform ──
install_terraform

# ── 4. Signal ready ──
finish_setup
