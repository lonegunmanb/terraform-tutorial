# =============================================
# 🧪 输出值练习
# =============================================
# 完成以下四道练习，然后运行 terraform test 验证答案。
#
# 运行命令：
#   terraform test
#
# 所有测试通过即为完成！
# =============================================


# ── 练习 1：基础输出值 ──
# 给定以下变量（已定义好，请勿修改）：
variable "project_name" {
  type    = string
  default = "my-app"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

# 定义两个 output：
#   1. output "project"：value 为 var.project_name，description 为 "The project name."
#   2. output "deployment_region"：value 为 var.region，description 为 "The deployment region."

# >>> 在此处写入你的代码 <<<


# ── 练习 2：输出表达式 ──
# 使用上面已定义的 var.project_name 和 var.region
# 定义一个 output "resource_prefix"：
#   value 为 project_name 和 region 用 "-" 连接的字符串
# 期望结果（使用默认变量值）："my-app-us-east-1"

# >>> 在此处写入你的代码 <<<


# ── 练习 3：sensitive 输出 ──
# 给定以下变量（已定义好，请勿修改）：
variable "db_password" {
  type      = string
  default   = "s3cret!Pass"
  sensitive = true
}

# 定义一个 output "db_connection_url"：
#   value 为 "postgresql://admin:<PASSWORD>@localhost:5432/mydb"
#   其中 <PASSWORD> 替换为 var.db_password
#   标记为 sensitive
# 期望结果："postgresql://admin:s3cret!Pass@localhost:5432/mydb"

# >>> 在此处写入你的代码 <<<


# ── 练习 4：precondition ──
# 给定以下变量（已定义好，请勿修改）：
variable "server_count" {
  type    = number
  default = 3
}

# 1. 定义 locals 块，其中 servers 为一个列表：
#    使用 for 表达式，遍历 range(var.server_count)，
#    每个元素是一个 object：{ name = "server-<i>", ip = "10.0.0.<i+1>" }
#    例如 i=0 时：{ name = "server-0", ip = "10.0.0.1" }
#
# 2. 定义一个 output "primary_server_ip"：
#    value 为 local.servers[0].ip
#    添加 precondition：var.server_count 必须大于 0
#    error_message 为 "至少需要 1 台服务器。"

# >>> 在此处写入你的代码 <<<
