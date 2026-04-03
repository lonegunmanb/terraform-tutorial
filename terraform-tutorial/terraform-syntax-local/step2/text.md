# 第二步：练习与测试

现在轮到你来写代码了！完成四道练习题，然后用 terraform test 验证答案。

## 查看练习文件

```bash
cd /root/workspace/step2
cat exercises.tf
```

文件中有四道练习，每道都标有 >>> 在此处写入你的代码 <<< 的提示。

## 练习说明

### 练习 1：基础局部值

在 locals 块中定义两个局部值：

- app_name，值为 "web-server"
- app_port，值为 8080

### 练习 2：引用与计算

变量 env 已经定义好（默认值为 "staging"）。在 locals 块中定义：

- full_name：将 app_name 和 env 用 "-" 连接，即 "web-server-staging"
- is_production：当 env 等于 "prod" 时为 true，否则为 false

### 练习 3：复杂表达式

变量 users 已经定义好（包含 ["alice", "bob", "charlie"]）。在 locals 块中定义：

- user_count：用户数量（使用 length 函数）
- upper_users：所有用户名转为大写的列表（使用 for 表达式 + upper 函数）
- user_tags：以用户名为键、"active" 为值的 map（使用 for 表达式）

### 练习 4：标签合并

变量 custom_tags 已经定义好。在 locals 块中定义 merged_tags：

- 将默认标签 { App = local.app_name, Env = var.env } 与 var.custom_tags 合并
- 使用 merge(map1, map2) 函数

期望结果：{ App = "web-server", Env = "staging", Team = "platform" }

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
  run "check_basic_locals"... pass
  run "check_reference"... pass
  run "check_complex"... pass
  run "check_merge"... pass

Success! 4 passed, 0 failed.
```

如果有测试失败，错误信息会告诉你哪道练习有问题，修改后重新运行 terraform test 即可。

✅ 所有测试通过后，你就完成了局部值的学习！
