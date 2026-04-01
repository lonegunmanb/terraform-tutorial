# 第三步：练习与测试

现在轮到你来写代码了！完成三道练习题，然后用 terraform test 验证答案。

## 查看练习文件

```bash
cd /root/workspace/step3
cat exercises.tf
```

文件中有三道练习，每道都标有 >>> 在此处写入你的代码 <<< 的提示。

## 练习说明

### 练习 1：定义 locals 块

定义一个 locals 块，包含两个值：

```hcl
project_name = "terraform-tutorial"
environment  = "lab"
```

### 练习 2：Heredoc 多行字符串

再定义一个 locals 块，包含一个 server_config 值，使用 <<-EOF 语法定义以下内容：

```
server {
  listen 80;
  server_name example.com;
}
```

### 练习 3：字符串插值

创建一个 output "project_info" 块，使用 \${} 插值组合 local.project_name 和 local.environment，期望输出：

```
terraform-tutorial-lab
```

## 编辑文件

用编辑器修改 exercises.tf，完成三道练习。

不要修改 outputs.tf 和 tests/ 目录中的文件，它们用于自动验证你的答案。

## 验证答案

完成编辑后，运行测试：

```bash
terraform test
```

如果所有测试通过，你会看到类似输出：

```
tests/exercises.tftest.hcl... pass
  run "check_locals"... pass
  run "check_heredoc"... pass
  run "check_interpolation"... pass

Success! 3 passed, 0 failed.
```

如果有测试失败，错误信息会告诉你哪道练习有问题，修改后重新运行 terraform test 即可。

✅ 所有测试通过后，你就完成了配置语法的学习！
