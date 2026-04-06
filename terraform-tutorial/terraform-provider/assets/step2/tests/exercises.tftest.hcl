run "check_answers" {

  assert {
    condition     = output.check_aws_source == "hashicorp/aws"
    error_message = "练习 1 错误：AWS Provider 的源地址应为 \"hashicorp/aws\"（namespace 是 hashicorp，type 是 aws）"
  }

  assert {
    condition     = output.check_google_local_name == "google"
    error_message = "练习 2 错误：google_compute_instance 对应的 Provider 本地名称应为 \"google\"（取下划线前的第一个单词）"
  }

  assert {
    condition     = output.check_aws_full_source == "registry.terraform.io/hashicorp/aws"
    error_message = "练习 3 错误：完全限定地址应为 \"registry.terraform.io/hashicorp/aws\"（补全默认的 hostname）"
  }

}
