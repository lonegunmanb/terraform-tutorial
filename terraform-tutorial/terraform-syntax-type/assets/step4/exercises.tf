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
