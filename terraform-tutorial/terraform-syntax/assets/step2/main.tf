# ==============================
# Terraform 配置语法示例：注释与字符串
# ==============================

# 这是单行注释（推荐风格）

// 这也是单行注释（C 风格，不推荐）

/*
  这是多行注释
  可以跨越多行
*/

locals {
  # ── 普通字符串 ──
  greeting = "Hello, Terraform!"

  # ── 字符串插值：用 ${} 引用其他值 ──
  message = "Project says: ${local.greeting}"

  # ── Heredoc 语法：<<EOF 保留原始缩进 ──
  config_raw = <<EOF
server {
  listen 80;
  server_name example.com;
}
EOF

  # ── 缩进 Heredoc：<<-EOF 去除公共前导空格 ──
  config_clean = <<-EOF
    server {
      listen 80;
      server_name example.com;
    }
  EOF

  # ── 转义字符 ──
  escaped = "第一行\n第二行\t带制表符"

  # ── 转义插值：$${} 输出字面量 ──
  literal = "这不是插值：$${not_a_ref}"
}

output "greeting" {
  value = local.greeting
}

output "message" {
  value = local.message
}

output "config_raw" {
  value = local.config_raw
}

output "config_clean" {
  value = local.config_clean
}

output "literal" {
  value = local.literal
}
