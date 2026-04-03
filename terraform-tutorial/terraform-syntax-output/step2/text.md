# 第二步：sensitive 与 precondition

输出值经常包含密码、密钥等敏感信息。Terraform 提供了 sensitive 标记来隐藏这些值。precondition 则允许你在输出前校验条件。

## 查看示例代码

```bash
cd /root/workspace/step2
cat main.tf
```

代码展示了两大主题：

### sensitive 输出

将 sensitive 设为 true 后：

- terraform apply 输出中显示 `<sensitive>` 代替真实值
- terraform output 也显示 `<sensitive>`
- 但 terraform output -json 仍可看到实际值

如果输出值引用了一个 sensitive 变量，该输出也必须标记为 sensitive，否则 Terraform 会报错。

### precondition 输出

precondition 在计算 value 表达式之前执行检查：

- condition 为 true 时正常输出
- condition 为 false 时 Terraform 报错并显示 error_message
- 可以防止不合法的值被写入状态文件

## 运行代码

```bash
terraform init
terraform apply -auto-approve
```

注意观察输出：

- database_password 和 connection_string 显示为 `<sensitive>`
- api_endpoint 正常显示
- admin_credentials 也显示为 `<sensitive>`

## 查看 sensitive 输出的实际值

```bash
terraform output database_password
```

显示 `<sensitive>`。要看实际值：

```bash
terraform output -json database_password
```

或者用 -raw 参数（适合赋值给 shell 变量）：

```bash
terraform output -raw database_password
```

## 验证 precondition

当前 instance_count 为 3，precondition 通过。试试把它设为 0：

```bash
terraform plan -var="instance_count=0"
```

你会看到类似错误：

```
Error: Resource precondition failed
  至少需要 1 个实例才能输出 primary_server。
```

再试试超过上限：

```bash
terraform plan -var="instance_count=20"
```

```
Error: Resource precondition failed
  实例数量不能超过 10 个。
```

## 关键点

- sensitive 只影响命令行输出，状态文件中仍是明文
- 引用 sensitive 变量的输出也必须标记 sensitive
- terraform output -json 可以看到 sensitive 的实际值
- precondition 在 value 表达式之前执行，可以提前拦截错误
- precondition 保护的是状态文件中的数据一致性

✅ 你已经掌握了 sensitive 和 precondition 的用法。
