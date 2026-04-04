# 第二步：小测验 — 编写重载文件

在这一步中，你将独立编写一个重载文件来检验对合并规则的理解。main.tf 中已经提供了完整的配置和输出，你需要创建一个 override.tf 来覆盖指定的值，然后用 terraform test 验证答案。

## 查看代码

```bash
cd /root/workspace/step2
cat main.tf
```

观察代码结构：

- **变量**：`app_name`（默认 "webapp"）、`instance_count`（默认 1）
- **局部值**：`region`、`environment`（默认 "dev"）、`prefix`
- **资源**：SQS 队列（`tasks`）和 S3 存储桶（`artifacts`）
- **输出**：队列名称、可见性超时、桶 ID、prefix、environment、instance_count
- **文件末尾的注释**中列出了 4 道题目

先初始化并确认当前配置可以正常工作：

```bash
terraform init
terraform plan
```

## 完成题目

阅读 main.tf 末尾的注释，创建一个 override.tf 文件来完成以下覆盖：

**第 1 题**：将 variable "instance_count" 的默认值改为 3

**第 2 题**：将 locals 中的 environment 改为 "prod"

**第 3 题**：将 aws_sqs_queue "tasks" 的 visibility_timeout_seconds 改为 60

**第 4 题**：将 aws_s3_bucket "artifacts" 的 tags 改为只包含 { CostCenter = "engineering" }

所有修改都写在同一个 override.tf 文件中。用编辑器或命令行编辑：

```bash
cat > override.tf <<'EOF'
# 在这里写入你的重载配置
EOF
```

## 验证答案

补全 override.tf 后，先确认 plan 不报错：

```bash
terraform plan
```

然后用 terraform test 运行自动化测试：

```bash
terraform test
```

如果全部正确，你会看到类似这样的输出：

```
override_test.tftest.hcl... in progress
  run "test_instance_count_overridden"... pass
  run "test_environment_overridden"... pass
  run "test_prefix_reflects_override"... pass
  run "test_queue_visibility_timeout"... pass
  run "test_queue_name_uses_prod"... pass
  run "test_bucket_uses_prod_prefix"... pass
override_test.tftest.hcl... tearing down
override_test.tftest.hcl... pass

Success! 6 passed, 0 failed.
```

如果某道题写错了，测试会告诉你哪一题的断言失败。根据错误信息修正 override.tf 后重新运行 terraform test 即可。

## 提示

- 重载文件中定义的 variable 块只需要写 default，不需要重复 type
- 重载 locals 时只需要写要覆盖的命名值
- 重载 resource 参数时只需要写要覆盖的参数
- tags 是普通参数，会被完全覆盖（不是合并）

## 关键点

- 重载文件必须命名为 override.tf 或以 _override.tf 结尾
- 变量重载保持 type 不变，只覆盖 default
- locals 按名称逐条合并
- 资源参数被逐条覆盖，tags 作为参数被完全替换
- terraform test 可以自动验证重载效果

恭喜你完成了重载文件的学习！
