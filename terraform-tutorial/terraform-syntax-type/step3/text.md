# 第三步：结构化类型

结构化类型允许多个**不同类型**的值组成一个复合类型。

## 查看示例代码

```bash
cd /root/workspace/step3
cat main.tf
```

### object 与 tuple

| 类型 | 描述 | 示例 |
|------|------|------|
| `object({...})` | 命名属性，每个属性有独立的类型 | `object({name=string, age=number})` |
| `tuple([...])` | 定长序列，每个位置有独立的类型 | `tuple([string, number, bool])` |

**`object` 与 `map` 的区别**：`map` 的所有值必须是同一类型，`object` 的每个属性可以是不同类型。

**`tuple` 与 `list` 的区别**：`list` 的所有元素必须是同一类型，`tuple` 的每个位置可以是不同类型。

### optional 修饰符（Terraform >= 1.3）

`object` 类型中可以使用 `optional` 声明可选属性：

```hcl
variable "config" {
  type = object({
    name     = string                    # 必填
    port     = optional(number, 8080)    # 可选，默认 8080
    debug    = optional(bool, false)     # 可选，默认 false
  })
}
```

- 省略 `optional` 属性时 → 使用指定的默认值
- 未指定默认值的 `optional` 属性 → 默认为 `null`

### any 与 null

- **`any`**：类型占位符，不是真正的类型。Terraform 会根据实际赋值推断具体类型。
- **`null`**：表示"缺失"。如果参数设为 `null` 且有默认值，Terraform 使用默认值；如果是必填参数，则报错。`null` 在条件表达式中很有用——可以在某条件不满足时跳过赋值。

## 运行代码观察

```bash
terraform plan
```

注意 `db_version`、`db_port` 等输出——我们只给 `database` 设了 `engine`，其他属性都获得了 `optional` 指定的默认值。

## 用 console 交互探索

```bash
terraform console
```

在 console 中尝试：

```
var.server
var.server.name
var.record
var.record[1]
var.database
var.database.version
var.database.config.max_connections
var.maybe_name == null
local.display_name
```

按 Ctrl+C 退出 console。
