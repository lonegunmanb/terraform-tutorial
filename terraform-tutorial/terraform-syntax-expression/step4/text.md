# 第四步：练习与测试

现在轮到你来写代码了！完成四道练习题，然后用 terraform test 验证答案。

## 查看练习文件

```bash
cd /root/workspace/step4
cat exercises.tf
```

文件中有四道练习，每道都标有 >>> 在此处写入你的代码 <<< 的提示。

## 练习说明

### 练习 1：条件表达式

定义一个 variable "score"，类型为 number，默认值为 85。然后在 locals 块中定义 grade：

- score >= 60 时为 "pass"
- 否则为 "fail"

### 练习 2：for 表达式（过滤与转换）

变量 words 已经定义好（包含空字符串）。在 locals 块中定义 clean_words：

- 过滤掉空字符串
- 将剩余元素转为大写

期望结果：["HELLO", "WORLD", "TERRAFORM"]

### 练习 3：for 表达式（生成 map）

变量 users 已经定义好（包含 name 和 role）。在 locals 块中定义 user_roles：

- 使用 for 表达式，以 name 为键、role 为值生成 map

期望结果：{ "alice" = "admin", "bob" = "dev", "carol" = "admin" }

### 练习 4：splat 表达式

使用已定义的 var.users，在 locals 块中定义 user_names：

- 使用 splat 表达式 [*] 提取所有用户的 name

期望结果：["alice", "bob", "carol"]

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
  run "check_conditional"... pass
  run "check_for_filter"... pass
  run "check_for_map"... pass
  run "check_splat"... pass

Success! 4 passed, 0 failed.
```

如果有测试失败，错误信息会告诉你哪道练习有问题，修改后重新运行 terraform test 即可。

✅ 所有测试通过后，你就完成了表达式的学习！
