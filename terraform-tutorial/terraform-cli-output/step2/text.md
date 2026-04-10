# 第二步：-json、-raw 与脚本集成

## -raw：直接获取字符串值

-raw 输出不带引号的原始字符串，适合直接赋值给 shell 变量：

```
cd /root/workspace
terraform output -raw app_bucket
echo ""
```

注意输出末尾没有换行符，所以加了 echo 换行。对比不带 -raw 的输出（带引号）：

```
terraform output app_bucket
```

在脚本中使用 -raw 赋值给变量：

```
BUCKET=$(terraform output -raw app_bucket)
echo "桶名: $BUCKET"
awslocal s3api head-bucket --bucket "$BUCKET" && echo "桶存在"
```

-raw 只支持 string、number、bool 类型。对复合类型使用 -raw 会报错：

```
terraform output -raw all_bucket_names || true
```

复合类型必须用 -json。

## -json：机器可读输出

查看所有 output 的 JSON 表示：

```
terraform output -json | python3 -m json.tool
```

每个 output 包含 value、type、sensitive 三个字段。注意 sensitive 的 output 在 -json 中也以明文显示。

查看单个 output 的 JSON：

```
terraform output -json app_bucket
```

单个 string output 的 JSON 是一个带引号的字符串值。单个 list output 的 JSON：

```
terraform output -json all_bucket_names
```

输出为 JSON 数组。

## 用 python3 提取复合类型中的值

从 list 中提取第一个元素：

```
terraform output -json all_bucket_names | python3 -c "import sys,json; print(json.load(sys.stdin)[0])"
```

从 map 中提取指定 key：

```
terraform output -json resource_summary | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['app_bucket'])"
```

## 导出 output 供后续步骤使用

在 CI/CD 中，经常需要将 output 导出供后续阶段使用：

```
terraform output -json > outputs.json
cat outputs.json | python3 -c "
import sys, json
data = json.load(sys.stdin)
for name, info in data.items():
    sensitive_mark = ' [SENSITIVE]' if info.get('sensitive') else ''
    print(f\"{name} = {info['value']}{sensitive_mark}\")
"
```

用 -raw 导出单个值到文件：

```
terraform output -raw sessions_table > table_name.txt
cat table_name.txt
echo ""
```

清理临时文件：

```
rm -f outputs.json table_name.txt
```

确认对 -json 和 -raw 的区别已理解后进入完成页。
