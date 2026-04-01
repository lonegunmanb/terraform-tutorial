#!/bin/bash
exec > /tmp/background.log 2>&1
set -x

source /root/setup-common.sh

# ── 1. Ensure workspace directories exist ──
mkdir -p /root/workspace/step1
mkdir -p /root/workspace/step2
mkdir -p /root/workspace/step3/tests

# ── 2. Seed workspace files (fallback if assets copy fails) ──

if [ ! -f /root/workspace/step1/main.tf ]; then
cat > /root/workspace/step1/main.tf <<'EOTF'
# ==============================
# Terraform 配置语法示例：块与参数
# ==============================

# ── terraform 块：无标签 ──
terraform {
  required_version = ">= 1.0"
}

# ── locals 块：无标签，定义局部变量 ──
# Terraform 允许定义多个 locals 块，但所有块中的 key 必须唯一
locals {
  # 参数赋值：名称 = 值
  project = "my-app"
  region  = "us-east-1"

  # 不同类型的值
  enabled = true
  count   = 3
}

# ── 可以定义多个 locals 块，按用途分组 ──
locals {
  # Map 类型
  tags = {
    Environment = "dev"
    Team        = "platform"
  }

  # List 类型
  zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# ── output 块：一个标签（输出名称）──
output "project" {
  value       = local.project
  description = "项目名称"
  # => "my-app"
}

output "tags" {
  value = local.tags
  # => { Environment = "dev", Team = "platform" }
}

output "zones" {
  value = local.zones
  # => ["us-east-1a", "us-east-1b", "us-east-1c"]
}
EOTF
fi

if [ ! -f /root/workspace/step2/main.tf ]; then
cat > /root/workspace/step2/main.tf <<'EOTF'
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
  # local.greeting = "Hello, Terraform!"，所以：
  message = "Project says: ${local.greeting}"
  # => "Project says: Hello, Terraform!"

  # ── Heredoc 语法：<<EOF 保留原始缩进 ──
  # 内容从第二行开始，保留所有缩进原样输出
  config_raw = <<EOF
server {
  listen 80;
  server_name example.com;
}
EOF

  # ── 缩进 Heredoc：<<-EOF 去除公共前导空格 ──
  # 与上面输出相同，但允许代码中缩进对齐，更整洁
  config_clean = <<-EOF
    server {
      listen 80;
      server_name example.com;
    }
  EOF

  # ── 转义字符 ──
  escaped = "第一行\n第二行\t带制表符"
  # => 输出时 \n 变换行，\t 变制表符

  # ── 转义插值：$${} 输出字面量 ──
  literal = "这不是插值：$${not_a_ref}"
  # => "这不是插值：${not_a_ref}"
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
EOTF
fi

if [ ! -f /root/workspace/step3/exercises.tf ]; then
cat > /root/workspace/step3/exercises.tf <<'EOTF'
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
EOTF
fi

if [ ! -f /root/workspace/step3/outputs.tf ]; then
cat > /root/workspace/step3/outputs.tf <<'EOTF'
# 此文件用于测试验证，请勿修改

output "check_project_name" {
  value = local.project_name
}

output "check_environment" {
  value = local.environment
}

output "check_server_config" {
  value = local.server_config
}
EOTF
fi

if [ ! -f /root/workspace/step3/tests/exercises.tftest.hcl ]; then
cat > /root/workspace/step3/tests/exercises.tftest.hcl <<'EOTF'
run "check_locals" {
  command = plan

  assert {
    condition     = output.check_project_name == "terraform-tutorial"
    error_message = "练习 1 未通过：local.project_name 应为 \"terraform-tutorial\""
  }

  assert {
    condition     = output.check_environment == "lab"
    error_message = "练习 1 未通过：local.environment 应为 \"lab\""
  }
}

run "check_heredoc" {
  command = plan

  assert {
    condition     = can(regex("listen 80", output.check_server_config))
    error_message = "练习 2 未通过：local.server_config 应包含 \"listen 80\"（使用 heredoc 语法）"
  }

  assert {
    condition     = can(regex("server_name example\\.com", output.check_server_config))
    error_message = "练习 2 未通过：local.server_config 应包含 \"server_name example.com\""
  }
}

run "check_interpolation" {
  command = plan

  assert {
    condition     = output.project_info == "terraform-tutorial-lab"
    error_message = "练习 3 未通过：output.project_info 应为 \"terraform-tutorial-lab\"（使用字符串插值）"
  }
}
EOTF
fi

# ── 3. Install Terraform ──
install_terraform

# ── 4. Pre-init all step directories ──
for dir in /root/workspace/step1 /root/workspace/step2 /root/workspace/step3; do
  cd "$dir"
  terraform init -input=false
done

finish_setup
