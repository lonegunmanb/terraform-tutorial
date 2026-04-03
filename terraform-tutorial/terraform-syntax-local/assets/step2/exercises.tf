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
#   - full_name：值为 local.app_name 和 var.env 用 "-" 连接，如 "web-server-staging"
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
#     提示：可以用 upper 函数将字符串转大写
#   - user_tags：以用户名为键、"active" 为值的 map

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
