# =============================================
# 🧪 Provider 配置练习
# =============================================
# 完成以下三道练习，然后运行 terraform test 验证答案。
#
# 运行命令：
#   terraform test
#
# 所有测试通过即为完成！
# =============================================


# ── 练习 1：AWS Provider 的源地址 ──
# AWS Provider 由 HashiCorp 官方维护并发布在 Terraform Registry 上。
# 请写出它的源地址（格式：namespace/type）
#
# 提示：格式类似 "某组织/某平台"

locals {
  # TODO: 将 "____" 替换为正确的源地址
  aws_provider_source = "____"
}


# ── 练习 2：资源类型与 Provider 的关系 ──
# 如果你在代码中看到一个资源类型是 google_compute_instance
# Terraform 会默认去寻找哪个 Provider 的本地名称？
#
# 提示：Terraform 取资源类型名下划线前的第一个单词

locals {
  # TODO: 将 "____" 替换为 Provider 的本地名称
  google_provider_local_name = "____"
}


# ── 练习 3：完全限定的源地址 ──
# 当你在 required_providers 中写 source = "hashicorp/aws" 时，
# Terraform 内部实际使用的完全限定源地址是什么？
#
# 提示：省略 hostname 时，Terraform 默认补全 registry.terraform.io

locals {
  # TODO: 将 "____" 替换为完全限定的源地址
  aws_full_source = "____"
}
