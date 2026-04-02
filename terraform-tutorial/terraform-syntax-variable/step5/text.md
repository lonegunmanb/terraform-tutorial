# 第五步：综合练习

综合运用前四步学到的知识，用输入变量驱动创建一个真实的 EC2 实例（运行在 LocalStack 上），然后用 terraform test 验证。

## 查看练习文件

```bash
cd /root/workspace/step5
cat exercises.tf
```

文件中有四道练习，每道都标有 >>> 在此处写入你的代码 <<< 的提示。

## 练习说明

### 练习 1：定义实例名称变量（带 validation）

定义一个名为 instance_name 的 variable 块：
- 类型为 string
- 默认值为 "my-tutorial-vm"
- 添加 validation 块：名称长度必须在 3 到 30 个字符之间（含边界）
- error_message 为 "instance_name 长度必须在 3-30 个字符之间。"

### 练习 2：定义实例类型变量（带枚举校验）

定义一个名为 instance_type 的 variable 块：
- 类型为 string
- 默认值为 "t2.micro"
- 添加 validation 块：只允许 "t2.micro"、"t2.small"、"t2.medium" 三个值
- error_message 为 "instance_type 必须是 t2.micro、t2.small 或 t2.medium 之一。"

### 练习 3：定义 sensitive 的标签变量

定义一个名为 owner 的 variable 块：
- 类型为 string
- 默认值为 "ops-team"
- 设置 sensitive = true

### 练习 4：用变量创建 EC2 实例

创建一个 aws_instance 资源，名称为 "exercise"：
- ami 使用 "ami-0c55b159cbfafe1f0"
- instance_type 使用 var.instance_type
- tags 包含 Name = var.instance_name 和 Owner = var.owner

## 编辑文件

用编辑器修改 exercises.tf，完成四道练习。

> 注意：不要修改 outputs.tf、provider.tf 和 tests/ 目录中的文件，它们用于自动验证你的答案。

## 验证答案

完成编辑后，运行测试：

```bash
terraform test
```

如果所有测试通过，你会看到类似输出：

```
tests/exercises.tftest.hcl... pass
  run "create_instance_with_defaults"... pass
  run "validate_instance_name_length"... pass
  run "validate_instance_type_enum"... pass
  run "create_instance_with_custom_vars"... pass

Success! 4 passed, 0 failed.
```

测试做了这些事情：

- create_instance_with_defaults —— 用默认值真实创建 EC2 实例，验证 instance_type 和 instance_name 是否正确
- validate_instance_name_length —— 故意传入长度为 2 的名称 "ab"，验证 validation 拦截非法输入
- validate_instance_type_enum —— 故意传入 "t2.xlarge"，验证枚举校验
- create_instance_with_custom_vars —— 传入自定义变量值创建另一个实例，验证变量正确传递

如果有测试失败，错误信息会告诉你哪道练习有问题，修改后重新运行 terraform test 即可。

✅ 所有测试通过后，你就完成了输入变量的学习！
