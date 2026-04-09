# 第三步：JSON 机器可读输出

## 状态的 JSON 输出

使用 -json 查看当前状态的 JSON 表示：

```
cd /root/workspace
terraform show -json | python3 -m json.tool | head -30
```

JSON 输出的顶层结构包含：

- format_version：JSON 格式版本
- terraform_version：Terraform 版本号
- values：所有资源和 output 的实际属性值

## 从 JSON 中提取资源信息

用 python3 提取所有受管资源的类型和名称：

```
terraform show -json | python3 -c "
import sys, json
data = json.load(sys.stdin)
for r in data['values']['root_module']['resources']:
    print(f\"{r['type']}.{r['name']}  →  {r['values'].get('bucket', r['values'].get('name', '-'))}\")
"
```

输出每个资源的地址和关键标识（桶名或表名），适合在脚本中快速获取资源清单。

## 计划文件的 JSON 输出

生成一个有变更的计划，然后用 -json 查看：

```
sed -i 's/billing_mode = "PAY_PER_REQUEST"/billing_mode = "PROVISIONED"\n  read_capacity  = 5\n  write_capacity = 5/' main.tf
terraform plan -out=tfplan
```

查看计划 JSON 的顶层结构：

```
terraform show -json tfplan | python3 -c "import sys, json; [print(k) for k in json.load(sys.stdin)]"
```

计划 JSON 比状态 JSON 多了几个关键字段：

- variables：输入变量及其值
- planned_values：变更后的预期状态
- resource_changes：每个资源的变更动作（create/update/delete）和前后属性差异
- prior_state：变更前的状态快照

## 从计划 JSON 中提取变更摘要

提取哪些资源将被变更以及变更类型：

```
terraform show -json tfplan | python3 -c "
import sys, json
data = json.load(sys.stdin)
for c in data.get('resource_changes', []):
    actions = ', '.join(c['change']['actions'])
    print(f\"{c['address']}  →  {actions}\")
"
```

这类脚本在 CI/CD 中非常实用——可以自动判断计划中是否包含危险操作（如 delete），并据此决定是否需要人工审批。

## 导出状态用于离线分析

将完整的状态 JSON 导出到文件：

```
terraform show -json > state.json
python3 -c "
import json
with open('state.json') as f:
    data = json.load(f)
print(f\"Terraform 版本: {data['terraform_version']}\")
print(f\"资源数量: {len(data['values']['root_module']['resources'])}\")
for r in data['values']['root_module']['resources']:
    print(f\"  - {r['type']}.{r['name']}\")
"
```

恢复配置并清理：

```
git checkout main.tf 2>/dev/null || cp /root/updated-main.tf main.tf
rm -f tfplan state.json
terraform apply -auto-approve
```

确认 Apply complete 后进入完成页。
