# 第三步：练习与测试

现在轮到你来写代码了！完成四道练习题，然后用 terraform test 验证答案。

## 查看练习文件

```bash
cd /root/workspace/step3
cat exercises.tf
```

文件中有四道练习，每道都标有 >>> 在此处写入你的代码 <<< 的提示。

## 练习说明

### 练习 1：基础输出值

变量 project_name 和 region 已经定义好。定义两个 output：

- output "project"：value 为 var.project_name，description 为 "The project name."
- output "deployment_region"：value 为 var.region，description 为 "The deployment region."

### 练习 2：输出表达式

使用已定义的变量，定义一个 output "resource_prefix"：

- value 为 project_name 和 region 用 "-" 连接的字符串
- 期望结果（使用默认变量值）："my-app-us-east-1"

### 练习 3：sensitive 输出

变量 db_password 已经定义好（带 sensitive = true）。定义一个 output "db_connection_url"：

- value 为 "postgresql://admin:PASSWORD@localhost:5432/mydb"，其中 PASSWORD 替换为 var.db_password
- 标记为 sensitive

### 练习 4：precondition

变量 server_count 已经定义好。定义 locals 块中的 servers 列表（用 for 生成），然后定义一个 output "primary_server_ip"：

- value 为 servers 列表中第一个元素的 ip
- 添加 precondition：server_count 必须大于 0，否则提示 "至少需要 1 台服务器。"

## 编辑文件

用编辑器修改 exercises.tf，完成四道练习。

不要修改 outputs.tf 和 tests/ 目录中的文件，它们用于自动验证你的答案。

## 验证答案

完成编辑后，运行测试：

```bash
terraform test
```

如果所有测试通过，你会看到类似输出：

```
tests/exercises.tftest.hcl... pass
  run "check_basic_output"... pass
  run "check_expression_output"... pass
  run "check_sensitive_output"... pass
  run "check_precondition_output"... pass

Success! 4 passed, 0 failed.
```

如果有测试失败，错误信息会告诉你哪道练习有问题，修改后重新运行 terraform test 即可。

✅ 所有测试通过后，你就完成了输出值的学习！
