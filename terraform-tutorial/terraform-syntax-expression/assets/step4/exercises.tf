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
