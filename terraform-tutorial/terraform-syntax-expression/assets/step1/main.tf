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
