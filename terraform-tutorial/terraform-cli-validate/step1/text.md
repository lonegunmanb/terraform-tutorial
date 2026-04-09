# 第一步：validate 通过与失败

## 验证正确的配置

进入工作目录，先确认当前配置是合法的：

```
cd /root/workspace
terraform validate
```

输出：

```
Success! The configuration is valid.
```

validate 不连接远端服务，只检查语法和内部一致性，速度非常快。

## 属性名拼写错误

制造一个常见的拼写错误——把 bucket 写成 buckeet：

```
sed -i 's/bucket = "${var.app_name}/buckeet = "${var.app_name}/' main.tf
```

运行 validate：

```
terraform validate
```

Terraform 报错并给出修复建议：

```
Error: Unsupported argument

  An argument named "buckeet" is not expected here. Did you mean "bucket"?
```

注意 validate 精确定位了错误所在的文件和行号，还贴心地猜测了你想写的正确属性名。

恢复配置：

```
sed -i 's/buckeet = "${var.app_name}/bucket = "${var.app_name}/' main.tf
terraform validate
```

## 类型不匹配

将 string 类型的变量默认值改为一个数字：

```
sed -i 's/default     = "dev"/default     = 123/' main.tf
```

运行 validate：

```
terraform validate
```

Terraform 报错：

```
Error: Invalid default value for variable
```

default 值的类型（number）与声明的 type（string）不匹配。

恢复：

```
sed -i 's/default     = 123/default     = "dev"/' main.tf
terraform validate
```

## 引用不存在的变量

在 output 中引用一个不存在的变量：

```
sed -i 's/value = aws_s3_bucket.app.bucket/value = var.nonexistent/' main.tf
```

运行 validate：

```
terraform validate
```

报错：

```
Error: Reference to undeclared input variable
```

Terraform 能在不访问远端的情况下发现这个引用错误——这就是 validate 作为快速预检的价值。

恢复：

```
sed -i 's/value = var.nonexistent/value = aws_s3_bucket.app.bucket/' main.tf
terraform validate
```

确认显示 Success 后进入下一步。
