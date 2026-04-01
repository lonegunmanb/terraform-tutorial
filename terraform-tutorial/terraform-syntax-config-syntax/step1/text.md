# 第一步：块与参数

HCL 代码由**块**（Block）组成，块是 Terraform 配置的基本结构单元。

## 查看示例代码

```bash
cd /root/workspace/step1
cat main.tf
```

观察代码中不同类型的块：

- **terraform 块** — 无标签，配置 Terraform 自身的行为
- **locals 块** — 无标签，定义局部变量
- **output 块** — 一个标签（输出名称）

### 块的通用格式

```
块类型 "标签1" "标签2" {
  参数名 = 参数值
}
```

- **块类型**决定了块的用途（terraform、resource、variable、output、locals 等）
- **标签**的数量取决于块类型（有些块没有标签，有些有一个或两个）
- **参数**是“名称 = 值”的赋值语句

## 运行代码

```bash
terraform plan
```

注意输出中 output 块的值——Terraform 会计算 locals 中定义的值并通过 output 导出。

## 用 console 交互探索

```bash
terraform console
```

在 console 中尝试引用不同类型的值：

```
local.project
local.tags
local.tags["Environment"]
local.zones
local.zones[0]
local.count + 10
```

输入 exit 退出 console。

terraform console 是探索表达式和变量值的好工具，它会自动加载当前目录的配置。

✅ 你已经了解了块与参数的基本结构。
