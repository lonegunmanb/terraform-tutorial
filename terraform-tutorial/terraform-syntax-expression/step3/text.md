# 第三步：for 表达式与 splat

for 表达式和 splat 表达式是 Terraform 中处理集合数据的核心工具。

## 查看示例代码

```bash
cd /root/workspace/step3
cat main.tf
```

代码展示了以下用法：

### for 表达式

for 表达式将一种复合类型映射成另一种，语法为：

```hcl
# 输出元组（方括号）
[for item in collection : transform(item)]

# 输出对象（花括号 + =>）
{for item in collection : key_expr => value_expr}
```

关键变体：

- **过滤** — 添加 if 子句：[for s in list : upper(s) if s != ""]
- **遍历 map** — 两个迭代变量：[for k, v in map : ...]
- **分组** — 使用 ... 聚合同键的值：{for s in list : key => s...}

### splat 表达式

splat 是提取列表中所有元素某属性的简写：

```hcl
var.servers[*].name
# 等价于 [for s in var.servers : s.name]
```

## 运行代码

```bash
terraform plan
```

注意观察每个输出的结果，理解各种 for 表达式的变体。

## 用 console 探索

```bash
terraform console
```

试试这些表达式：

```
[for s in ["a", "b", "c"] : upper(s)]
[for i, s in ["a", "b", "c"] : "${i}-${s}"]
[for s in ["hello", "", "world"] : s if s != ""]
{for s in ["alice", "bob"] : s => upper(s)}
{for s in ["apple", "avocado", "banana"] : substr(s, 0, 1) => s...}
var.servers[*].name
var.servers[*].port
```

输入 exit 退出。

## 关键点

- 方括号 [] 包裹的 for 输出元组，花括号 {} 输出对象
- if 子句用于过滤，... 用于分组
- splat [*] 是 for 表达式的简写，只能用于提取单一属性

✅ 你已经掌握了 for 表达式和 splat 表达式。
