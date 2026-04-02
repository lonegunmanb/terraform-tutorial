# 第二步：字符串模板与函数调用

Terraform 的字符串模板和内建函数是构建动态配置的利器。

## 查看示例代码

```bash
cd /root/workspace/step2
cat main.tf
```

观察代码中的三大主题：

### 字符串插值

在双引号或 Heredoc 字符串中，\${} 嵌入表达式的计算结果：

```hcl
"Hello, ${var.name}!"
```

要输出字面量 \${}，用 \$\${} 转义。

### 字符串指令

%{} 序列用于条件判断和循环：

- %{ if condition }...%{ else }...%{ endif } — 条件选择
- %{ for item in list }...%{ endfor } — 遍历集合

在指令的首尾可以加 ~ 符号来去除多余的空白。

### 内建函数

Terraform 提供了大量内建函数，包括：

- 字符串函数（upper、lower、join、replace 等）
- 数值函数（min、max、abs 等）
- 集合函数（length、contains、sort、flatten 等）
- 类型转换函数（tostring、tonumber、tobool 等）
- 编码函数（jsonencode、jsondecode 等）

### 展开符

用 ... 把列表展开为函数参数：

```hcl
min([55, 2453, 2]...)  # => 2
```

## 运行代码

```bash
terraform plan
```

## 用 console 探索

```bash
terraform console
```

试试这些表达式：

```
upper("hello")
lower("WORLD")
length("terraform")
join("-", ["a", "b", "c"])
contains(["x", "y", "z"], "y")
min(10, 5, 20)
max([1, 2, 3]...)
abs(-99)
replace("foo-bar", "-", "_")
format("%.2f", 3.14159)
jsonencode({"key": "value"})
```

输入 exit 退出。

✅ 你已经掌握了字符串模板和函数调用。
