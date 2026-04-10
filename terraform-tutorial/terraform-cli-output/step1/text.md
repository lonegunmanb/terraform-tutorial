# 第一步：查看 output 值与 sensitive 行为

## 列出所有 output

进入工作目录，查看当前状态中所有 output 的值：

```
cd /root/workspace
terraform output
```

输出列出了根模块中声明的所有 output。注意 db_connection 显示为 &lt;sensitive&gt;——因为它在声明时标记了 sensitive = true。

## 按名称查询单个 output

查询某个特定 output 的值：

```
terraform output app_bucket
```

输出带引号的字符串值。再试试查看列表类型的 output：

```
terraform output all_bucket_names
```

输出为方括号包裹的列表。查看 map 类型：

```
terraform output resource_summary
```

输出为花括号包裹的键值对。

## sensitive output 的行为

前面列出所有 output 时，db_connection 显示为 &lt;sensitive&gt;。但按名称直接查询时，Terraform 会显示实际值：

```
terraform output db_connection
```

这是 Terraform 的设计：列出所有 output 时隐藏敏感值，防止意外泄露；但显式指定名称查询时，认为用户知道自己在做什么，因此返回实际值。

## output 与 show 的对比

terraform output 只显示 output 值，terraform show 展示整个状态（包含资源属性和 output）。对比两者：

```
terraform output
echo "---"
terraform show | tail -20
```

terraform show 的末尾包含了 output 值，但 terraform output 更简洁——只关注输出，不包含资源属性。

进入下一步学习 -json 和 -raw 的自动化用法。
