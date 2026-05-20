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

## Terraform 1.15+：显式类型转换（convert）

Terraform 大部分时候能自动推断类型，但下面这些情形容易出错：

- 条件表达式两端推断出的类型不一致（例如 var.flag 为真时返回 ["a"]，为假时返回 []，后者是空 tuple 而非 list of string）。
- 构造空集合：[] 是空 tuple、{} 是空 object，都没有元素类型，无法当作 list(string) 或 map(number) 使用。
- 相等比较 == 不会做隐式类型转换，类型不一致会一直返回 false。

Terraform 1.15 引入了内置 convert 函数，可以内联地把表达式强制转换为目标类型：

```hcl
locals {
  empty_tags   = convert([], list(string))
  empty_quotas = convert({}, map(number))

  subnets = convert(
    var.enable_private ? var.private_subnets : [],
    list(string),
  )
}
```

convert(value, type_constraint) 的第二个参数是类型约束表达式，写法与 variable 的 type 完全一致，可以表达 list(object({...})) 这类复合类型——这是老的 tolist / tomap / toset 做不到的。
