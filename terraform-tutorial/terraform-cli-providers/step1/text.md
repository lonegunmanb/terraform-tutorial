# 第一步：providers 依赖树与 schema

## 查看 provider 依赖树

进入工作目录，查看当前配置依赖了哪些 provider：

```
cd /root/workspace
terraform providers
```

输出显示依赖树结构，列出每个 provider 的源地址和版本约束。注意配置中使用了两个 provider：hashicorp/aws 和 hashicorp/random。

## 查看锁文件中的实际版本

terraform providers 显示的是配置中声明的版本约束，实际安装的精确版本记录在锁文件中：

```
cat .terraform.lock.hcl
```

锁文件中包含每个 provider 的精确版本号、平台信息和校验和哈希。

## 查看 provider schema

获取所有 provider 的完整 schema（JSON 格式）：

```
terraform providers schema -json | python3 -m json.tool | head -30
```

输出是一个巨大的 JSON 对象。用 python3 提取顶层结构：

```
terraform providers schema -json | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(f\"format_version: {data['format_version']}\")
for name in data['provider_schemas']:
    schema = data['provider_schemas'][name]
    resources = len(schema.get('resource_schemas', {}))
    datasources = len(schema.get('data_source_schemas', {}))
    print(f\"{name}: {resources} resources, {datasources} data sources\")
"
```

可以看到 aws provider 有数百个 resource 和 data source，random provider 则较少。

## 查询特定 resource 的属性定义

用 schema 查看 aws_s3_bucket 的属性：

```
terraform providers schema -json | python3 -c "
import sys, json
data = json.load(sys.stdin)
aws = data['provider_schemas']['registry.terraform.io/hashicorp/aws']
bucket = aws['resource_schemas']['aws_s3_bucket']
print('aws_s3_bucket attributes:')
for name, attr in sorted(bucket['block']['attributes'].items()):
    flags = []
    if attr.get('required'): flags.append('required')
    if attr.get('optional'): flags.append('optional')
    if attr.get('computed'): flags.append('computed')
    print(f'  {name}: {\" | \".join(flags)}')
"
```

这类查询适合在开发自动化工具或快速确认某个属性是必填还是可选时使用。

进入下一步学习 providers lock。
