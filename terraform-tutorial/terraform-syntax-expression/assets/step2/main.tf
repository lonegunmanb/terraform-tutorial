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
