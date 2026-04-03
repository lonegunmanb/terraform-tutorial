# 第一步：局部值的定义与使用

局部值是 Terraform 模块内部的"局部变量"，通过 locals 块定义，可以避免重复复杂表达式、提高代码可读性。

## 查看示例代码

```bash
cd /root/workspace/step1
cat main.tf
```

代码涵盖了局部值的核心知识点：

### 基础定义

- **locals 块**定义局部值，一个块可以包含多个局部值
- 一个模块中可以有**多个 locals 块**，按逻辑分组
- 局部值可以是各种类型：字符串、数字、布尔值、列表、map
- 通过 **local.名称**（注意是单数 local）引用局部值

### 常见使用场景

- **避免重复** — common_tags 使用 merge 合并标签，定义一次、多处引用
- **命名复杂表达式** — 给 var.environment == "prod" 起名为 is_production，提高可读性
- **预处理输入数据** — 用 trimspace 清洗 CIDR 列表中的空格
- **链式引用** — 局部值可以引用其他局部值，如 bucket_name 引用 base_name

## 运行代码

```bash
terraform plan
```

观察输出中各个局部值的结果。注意 full_name 是由 project 和 environment 拼接而成的，clean_cidrs 去除了原始数据中的多余空格。

## 用 console 交互探索

```bash
terraform console
```

在 console 中尝试引用各种局部值：

```
local.project
local.full_name
local.is_prod
local.common_tags
local.availability_zones
local.is_production
local.log_level
local.clean_cidrs
local.base_name
local.bucket_name
```

输入 exit 退出 console。

## 关键点

- 定义用 locals（复数），引用用 local（单数），不要混淆
- 局部值可以是任意类型，可以包含任意复杂的表达式
- 局部值之间可以互相引用，Terraform 会自动处理依赖关系
- 局部值只能在同一模块内使用
- 适合用于避免重复、命名复杂表达式、预处理数据
- 不要过度使用：如果一个表达式只用一次且含义清晰，不必提取为局部值

✅ 你已经掌握了局部值的定义和使用场景。
