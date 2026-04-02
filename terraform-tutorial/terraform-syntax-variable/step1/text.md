# 第一步：变量基础

输入变量用 variable 块定义，通过 var.NAME 引用。

## 查看示例代码

```bash
cd /root/workspace/step1
cat main.tf
```

### variable 块的结构

每个 variable 块由以下部分组成：

| 参数 | 作用 | 是否必填 |
|------|------|----------|
| type | 类型约束，限制变量接受的值的类型 | 可选 |
| default | 默认值，未赋值时使用 | 可选 |
| description | 描述，向调用者说明变量用途 | 可选（推荐写） |

示例结构：

```hcl
variable "project" {
  type        = string
  default     = "my-app"
  description = "项目名称"
}
```

### 引用变量

在代码中通过 var.NAME 引用变量值：

```hcl
locals {
  greeting = "Project: ${var.project}"
}
```

### 变量名限制

以下关键字不可以作为变量名：source、version、providers、count、for_each、lifecycle、depends_on、locals。

## 运行代码观察

```bash
terraform plan
```

观察输出，注意各个 output 的值：
- project 和 port 直接输出变量值
- greeting 和 full_label 使用了字符串插值
- status 使用了条件表达式

## 用 console 交互探索

```bash
terraform console
```

在 console 中尝试：

```
var.project
var.port
var.tags
var.tags["Environment"]
"${var.project}-${var.tags["Team"]}"
var.enabled ? "ON" : "OFF"
```

按 Ctrl+C 退出 console。

## 用 -var 覆盖默认值

在命令行中使用 -var 参数覆盖变量值：

```bash
terraform plan -var="project=hello-world" -var="port=3000"
```

观察输出——project 变成了 "hello-world"，port 变成了 3000，所有使用这些变量的表达式也随之改变。
