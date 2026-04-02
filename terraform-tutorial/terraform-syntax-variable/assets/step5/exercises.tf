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
