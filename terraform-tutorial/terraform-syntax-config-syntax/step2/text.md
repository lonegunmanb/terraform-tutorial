# 第二步：注释与字符串

## 查看示例代码

```bash
cd /root/workspace/step2
cat main.tf
```

### 注释

HCL 支持三种注释风格：

```
#          单行注释（推荐）
//         单行注释（C 风格，不推荐）
/* ... */  多行注释
```

### 字符串插值

在双引号字符串中，\${} 可以嵌入表达式：

```hcl
message = "Project says: ${local.greeting}"
```

如果需要输出字面量 \${}  ，用 \$\${} 转义：

```hcl
literal = "这不是插值：$${not_a_ref}"
```

### Heredoc 多行字符串

```
<<EOF     保留原始缩进
<<-EOF    去除每行的公共前导空格（推荐，代码更整洁）
```

## 运行代码，观察输出差异

```bash
terraform plan
```

注意观察 config_raw 和 config_clean 的区别——它们内容相同，但 <<-EOF 版本自动去除了缩进。

## 用 console 探索字符串

```bash
terraform console
```

试试这些表达式：

```
local.greeting
local.message
local.config_clean
local.literal
"${local.greeting} World"
upper(local.greeting)
length(local.greeting)
```

输入 exit 退出。

<<-EOF 是编写多行字符串的推荐方式，它允许你在代码中保持缩进对齐，同时生成的字符串不含多余的前导空格。

✅ 你已经掌握了注释和字符串的各种写法。
