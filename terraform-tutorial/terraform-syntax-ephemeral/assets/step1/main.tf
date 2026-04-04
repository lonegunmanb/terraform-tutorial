terraform {
  required_version = ">= 1.10"
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# ══════════════════════════════════════════
# 对比实验：resource vs ephemeral
# 同样使用 random_password，观察状态文件中的差异
# ══════════════════════════════════════════

# ── 方式 1：普通资源（密码会保存到状态文件）──
resource "random_password" "resource_password" {
  length  = 16
  special = true
}

# 普通资源的密码可以通过 output 输出
output "resource_password" {
  value     = random_password.resource_password.result
  sensitive = true
}

# ── 方式 2：临时资源（密码不会保存到状态文件）──
ephemeral "random_password" "ephemeral_password" {
  length  = 16
  special = true
}

# 临时资源的值可以通过 local 中转（local 本身也是临时的）
locals {
  eph_password = ephemeral.random_password.ephemeral_password.result
}

# 注意：ephemeral 值不能作为根模块的 output 输出
# 下面这样写会报错：
#   output "ephemeral_password" {
#     value     = local.eph_password
#     ephemeral = true
#   }
# 错误信息：Ephemeral output not allowed — 根模块不允许临时输出
