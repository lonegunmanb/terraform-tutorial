# 第二步：集合类型

集合类型包含一组**相同类型**的值。Terraform 支持三种集合类型。

## 查看示例代码

```bash
cd /root/workspace/step2
cat main.tf
```

### 三种集合类型

| 类型 | 描述 | 元素访问 |
|------|------|----------|
| `list(T)` | 有序集合，可重复 | 下标 `l[0]` |
| `map(T)` | 键值对，键为 string | 键名 `m["key"]` |
| `set(T)` | 无序，不重复 | 不支持下标，用 `contains()` |

其中 `T` 是元素类型，例如 `list(string)`、`map(number)`。

### 通配类型缩写

`list` 等价于 `list(any)`，`map` 等价于 `map(any)`，`set` 等价于 `set(any)`。

`any` 不是具体类型，而是占位符——它要求所有元素必须是同一类型。赋值时 Terraform 会自动推断实际类型，必要时进行隐式转换。例如 `["hello", 42, true]` 赋给 `list(any)` 后，所有元素会被转换为 `string`，结果为 `["hello", "42", "true"]`。

## 运行代码观察

```bash
terraform plan
```

观察各个 output 的值，特别注意 `mixed_to_string` 的隐式转换效果。

## ⚠️ "同一类型"的陷阱

`string`、`number`、`bool` 之间可以互转，所以混在一起没问题。但一旦混入**结构完全不同的类型**（比如 `string` 和 `list`，或 `string` 和 `object`），Terraform 就无法找到一个兼容的目标类型，会直接报错。

在 console 里试试这些会报错的表达式：

```bash
terraform console
```

```
# ✅ 能转换：string/number/bool 互转
tolist(["hello", 42, true])

# ❌ 报错：string 和 list 无法转为同一类型
tolist(["hello", ["a", "b"]])

# ❌ 报错：string 和 map/object 无法转为同一类型
tomap({name = "alice", config = { port = 8080 }})
```

> 💡 **经验法则**：`map(any)` 的所有值必须是同一类型。如果你想让不同键存放不同类型的值（比如一个是 `string`，另一个是 `object`），应该用 `object` 而不是 `map`。这是初学者最容易踩的坑之一。

## 用 console 交互探索

```bash
terraform console
```

在 console 中尝试集合操作：

```
var.availability_zones
var.availability_zones[0]
length(var.availability_zones)
var.tags["Environment"]
keys(var.tags)
values(var.tags)
contains(var.allowed_cidrs, "10.0.0.0/8")
var.ports[2]
```

按 `Ctrl+C` 退出 console。
