# 第一步：运算符与条件表达式

Terraform 表达式支持丰富的运算符和条件判断。

## 查看示例代码

```bash
cd /root/workspace/step1
cat main.tf
```

观察代码中的各种运算符：

- **算术运算符** — +、-、*、/、% 和负号
- **比较运算符** — ==、!=、<、>、<=、>=
- **逻辑运算符** — &&、||、!
- **条件表达式** — condition ? true_val : false_val

## 运行代码

```bash
terraform plan
```

观察输出中各个运算的结果。注意 10 / 3 的结果是小数，而 10 % 3 的结果是余数 1。

## 用 console 交互探索

```bash
terraform console
```

在 console 中尝试各种运算：

```
1 + 2 * 3
(1 + 2) * 3
10 % 3
5 > 3
5 == 5
true && false
true || false
!true
"dev" == "prod" ? "小实例" : "大实例"
3 > 5 ? "yes" : "no"
```

输入 exit 退出 console。

## 关键点

- 运算符有优先级，乘除优先于加减，可以用小括号改变优先级
- 条件表达式的两个候选值类型必须相同
- 条件表达式结合 null 可以实现可选赋值

✅ 你已经掌握了运算符和条件表达式的用法。
