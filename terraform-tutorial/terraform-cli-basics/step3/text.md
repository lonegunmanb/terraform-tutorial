# 第三步：terraform console — 交互式表达式计算

## 进入 console

terraform console 提供一个交互式 REPL，可实时求値任意 HCL 表达式。进入：

```bash
cd /root/workspace
terraform console
```

## 访问变量和 locals

输入以下表达式，每次一行（按 Enter 确认）：

```
var.environment
```

```
var.app_name
```

```
local.name_prefix
```

```
local.common_tags
```

你应该看到变量和 locals 的当前实际展开倦。

## 内置字符串函数

尝试常用的内置字符串函数：

```
length(local.name_prefix)
```

```
upper(var.app_name)
```

```
replace(local.name_prefix, "-", "_")
```

```
split("-", local.name_prefix)
```

## 内置集合函数

```
toset(["a", "b", "a", "c"])
```

```
length(toset(["a", "b", "a", "c"]))
```

```
contains(["dev", "staging", "prod"], var.environment)
```

## 条件表达式

```
var.environment == "dev" ? "开发环境" : "生产环境"
```

## for 表达式

```
{ for k, v in local.common_tags : k => lower(v) }
```

```
[for s in ["dev", "staging", "prod"] : upper(s)]
```

## 退出 console

输入 exit 或按 Ctrl+D 退出：

```
exit
```

> terraform console 是理解 HCL 内置函数和表达式的最佳工具。遇到不确定的表达式结果时，直接在这里验证。

