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

validate 不连接远端服务，只检查语法和内部一致性，速度非常快——即便此刻 miniblue 没有启动，validate 也能正常工作。

## 属性名拼写错误

制造一个常见的拼写错误——把 azurerm_resource_group 的 name 写成 naame：

```
sed -i 's/name     = "${var.app_name}/naame    = "${var.app_name}/' main.tf
```

运行 validate：

```
terraform validate
```

Terraform 报错并给出修复建议：

```
Error: Unsupported argument

  An argument named "naame" is not expected here. Did you mean "name"?
```

注意 validate 精确定位了错误所在的文件和行号，还贴心地猜测了你想写的正确属性名——这一切都不需要联网。

恢复配置：

```
sed -i 's/naame    = "${var.app_name}/name     = "${var.app_name}/' main.tf
terraform validate
```

## 类型不匹配

将 string 类型的变量默认值改为一个列表，制造类型冲突：

```
sed -i 's/default     = "dev"/default     = ["dev", "staging"]/' main.tf
```

运行 validate：

```
terraform validate
```

Terraform 报错：

```
Error: Invalid default value for variable

  on main.tf line 27, in variable "environment":
  27:   default     = ["dev", "staging"]

This default value is not compatible with the variable's type constraint: string required, but have tuple.
```

default 值的类型（list）与声明的 type（string）不匹配。注意：数字和布尔值可以隐式转换为 string，不会报错，必须使用 list 或 map 等复合类型才能触发此错误。

恢复：

```
sed -i 's/default     = \["dev", "staging"\]/default     = "dev"/' main.tf
terraform validate
```

## 引用不存在的变量

在 output 中引用一个不存在的变量：

```
sed -i 's/value = azurerm_resource_group.main.name/value = var.nonexistent/' main.tf
```

运行 validate：

```
terraform validate
```

报错：

```
Error: Reference to undeclared input variable

  on main.tf line 54, in output "resource_group":
  54:   value = var.nonexistent

An input variable with the name "nonexistent" has not been declared. This variable can be declared with a variable "nonexistent" {} block.
```

Terraform 能在不访问远端的情况下发现这个引用错误——这就是 validate 作为快速预检的价值。

恢复：

```
sed -i 's/value = var.nonexistent/value = azurerm_resource_group.main.name/' main.tf
terraform validate
```

确认显示 Success 后进入下一步。
