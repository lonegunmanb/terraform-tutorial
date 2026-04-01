# =============================================
# 🧪 配置语法练习
# =============================================
# 完成以下三道练习，然后运行 terraform test 验证答案。
#
# 运行命令：
#   terraform test
#
# 所有测试通过即为完成！
# =============================================


# ── 练习 1：定义 locals 块 ──
# 定义一个 locals 块，包含以下两个值：
#   project_name = "terraform-tutorial"
#   environment  = "lab"
#
# 提示：
#   locals {
#     key = "value"
#   }

# >>> 在此处写入你的代码 <<<


# ── 练习 2：Heredoc 多行字符串 ──
# 再定义一个 locals 块，包含一个 server_config 值，
# 使用 <<-EOF 语法定义以下内容：
#   server {
#     listen 80;
#     server_name example.com;
#   }
#
# 提示：Terraform 允许定义多个 locals 块

# >>> 在此处写入你的代码 <<<


# ── 练习 3：字符串插值 ──
# 创建一个 output 块，名称为 "project_info"
# 使用 "${}" 字符串插值组合 local.project_name 和 local.environment
# 格式为 "<project_name>-<environment>"
# 期望结果：terraform-tutorial-lab
#
# 提示：
#   output "name" {
#     value = "${local.xxx}-${local.yyy}"
#   }

# >>> 在此处写入你的代码 <<<
