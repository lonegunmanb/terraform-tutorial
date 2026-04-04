# 第三步：小测验 — 补全 ephemeral 块

在这一步中，你将亲手编写 ephemeral 块、local 和 write-only 资源属性来检验自己对临时资源的理解。main.tf 中已经提供了部分代码和输出，但缺少 3 处关键代码——你需要补全它们，然后用 terraform test 验证你的答案。

## 查看代码

```bash
cd /root/workspace/step3
cat main.tf
```

观察代码结构：

- 上半部分是**已提供的资源**：一个 Secrets Manager Secret
- 中间有 3 道题目，每道题要求你添加代码（注释中有详细提示）
- 下半部分是**已提供的输出**，引用了你需要补全的块

现在直接运行 plan 会报错：

```bash
terraform plan 2>&1 | head -20
```

## 完成题目

阅读 main.tf 中每道题目的注释，在指定位置添加代码。

**第 1 题**：添加一个 `ephemeral "random_password" "api_key"` 块，生成 20 字符的密码（不含特殊字符）

**第 2 题**：添加一个 `locals` 块，将 `ephemeral.random_password.api_key.result` 赋给 `local.api_key_value`

**第 3 题**：补全 `aws_secretsmanager_secret_version` 资源块，使用 `secret_string_wo` 和 `secret_string_wo_version` 属性将密码安全地写入 Secret

用编辑器或命令行编辑 main.tf。

## 验证答案

补全所有代码后，先确认 plan 不再报错：

```bash
terraform plan
```

然后用 terraform test 运行自动化测试：

```bash
terraform test
```

如果所有代码都正确，你会看到：

```
ephemeral_test.tftest.hcl... in progress
  run "test_secret_created"... pass
  run "test_ephemeral_password_length"... pass
  run "test_secret_name"... pass
ephemeral_test.tftest.hcl... tearing down
ephemeral_test.tftest.hcl... pass

Success! 3 passed, 0 failed.
```

如果某道题写错了，测试会告诉你哪个断言失败。根据错误信息修正 main.tf 后重新运行 terraform test 即可。

## 参考答案

如果你遇到困难，以下是每道题的提示：

**第 1 题提示**：

```
ephemeral "random_password" "api_key" {
  length  = 20
  special = false
}
```

**第 2 题提示**：

```
locals {
  api_key_value = ephemeral.random_password.api_key.result
}
```

**第 3 题提示**：

```
resource "aws_secretsmanager_secret_version" "api_key" {
  secret_id                = aws_secretsmanager_secret.api_key.id
  secret_string_wo         = local.api_key_value
  secret_string_wo_version = 1
}
```

再次运行测试确认全部通过：

```bash
terraform test
```

## 关键点

- ephemeral 块的语法是 `ephemeral "类型" "名称" { ... }`
- 临时资源的值必须通过 local 中转才能在其他地方使用
- write-only 属性（如 secret_string_wo）配合 ephemeral 实现零持久化
- terraform test 使用 .tftest.hcl 文件定义测试，自动管理资源生命周期

恭喜你完成了临时资源的学习！
