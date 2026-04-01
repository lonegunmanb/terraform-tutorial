# 第一步：原始类型

Terraform 有三种原始类型：string、number、bool。

## 查看示例代码

```bash
cd /root/workspace/step1
cat main.tf
```

### 三种原始类型

| 类型 | 描述 | 示例 |
|------|------|------|
| string | Unicode 字符串 | "hello" |
| number | 数字（整数或小数） | 42、43.14 |
| bool | 布尔值 | true、false |

### 隐式类型转换

number 和 bool 都可以与 string 互相隐式转换：

```
"42"    ↔ 42       字符串和数字互转
"true"  ↔ true     字符串和布尔值互转
"false" ↔ false
```

这意味着把 "42" 赋给 number 类型的变量不会报错，Terraform 会自动转换。

## 运行代码观察

```bash
terraform plan
```

注意输出中 computed_number 的值——字符串 "42" 被自动转换为数字后加 1 变成了 43。

## 用 console 交互探索

```bash
terraform console
```

在 console 中尝试类型转换：

```
var.name
var.port
type(var.port)
var.string_number + 10
"数字是：${var.port}"
```

按 Ctrl+C 退出 console。
