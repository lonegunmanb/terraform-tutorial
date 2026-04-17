# 第五步：状态隔离——用 Terragrunt + removed 块拆分状态

## 为什么还需要拆

回顾第一步的五个问题——代码层面已被模块化解决，但**状态**仍然是一个 terraform.tfstate：

- 改网络层的 plan 仍然刷新所有 30 个资源
- 改数据层仍然需要整个 state 的写锁
- 任何一层的操作失误都可能破坏其他层的状态

真正的生产环境需要**状态隔离**：每一层拥有独立的 state，互不干扰。

## 查看 Terragrunt 配置

```bash
cat /root/stage/step5/terragrunt.hcl
```

根 terragrunt.hcl 做两件事：
1. generate 块生成 provider.tf（所有层共用同一个 provider 配置）
2. inputs 块注入公共变量（suffix、app_name、environment）

注意 suffix —— 它替代了之前的 random_string 资源。我们先提取当前值：

```bash
SUFFIX=$(terraform state show random_string.suffix | grep 'result' | awk -F'"' '{print $2}')
echo "当前 suffix: $SUFFIX"
```

## 查看层级目录

```bash
find /root/stage/step5 -name "*.tf" -o -name "*.hcl" | sort
```

每个层级目录包含三个文件：

- main.tf：只保留本层的 module 调用 + 输入变量 + 输出
- removed.tf：用 removed 块释放不属于本层的资源（不销毁）
- terragrunt.hcl：声明对其他层的依赖

## 理解 removed 块

```bash
cat /root/stage/step5/networking/removed.tf
```

removed 块告诉 Terraform："这个资源/模块不再由我管理，但不要销毁它。" 和 moved 块的区别：

| 块 | 作用 | 资源命运 |
|----|------|---------|
| moved | 搬家：旧地址 → 新地址 | 留在当前 state |
| removed | 释放：从 state 中移除 | 交给其他 state 管理 |

## 理解 Terragrunt dependency

```bash
cat /root/stage/step5/web/terragrunt.hcl
```

web 层声明了两个依赖：

- dependency "networking"：读取 vpc_id、subnet_ids
- dependency "security"：读取 app_instance_profile_name

Terragrunt 自动从依赖层的 terraform output 获取值，通过 inputs 注入本层。

注意每个 dependency 都配置了 mock_outputs——在首次 init/plan 时依赖层尚未 apply，Terragrunt 会用 mock 值占位，apply 后才读取真实输出。

依赖图：

```
networking ─────┐
                ├──→ web
security ───────┘
  ↑
storage ────┤
data ───────┘
```

## 应用状态拆分

复制文件并设置 suffix：

```bash
cp -r /root/stage/step5/* /root/workspace/
sed -i "s/REPLACE_ME/$SUFFIX/" /root/workspace/terragrunt.hcl
```

把当前统一状态复制到每个层目录：

```bash
for layer in networking web data storage security; do
  cp /root/workspace/terraform.tfstate /root/workspace/$layer/
done
```

移除旧的根配置（各层有自己的配置了）：

```bash
rm /root/workspace/main.tf /root/workspace/moved.tf
```

## 初始化并应用

```bash
cd /root/workspace
terragrunt run-all init --terragrunt-non-interactive
```

Terragrunt 会按依赖关系拓扑排序，为每个层执行 terraform init。

```bash
terragrunt run-all apply -auto-approve --terragrunt-non-interactive -parallelism=2
```

每个层的 apply 做两件事：
1. removed 块从本层状态中释放不属于自己的资源（不销毁）
2. 保留的资源维持原样（零变更）

## 验证状态隔离

检查每个层的状态——现在各管各的：

```bash
echo "=== networking ==="
cd /root/workspace/networking && terraform state list
echo "=== web ==="
cd /root/workspace/web && terraform state list
echo "=== data ==="
cd /root/workspace/data && terraform state list
echo "=== storage ==="
cd /root/workspace/storage && terraform state list
echo "=== security ==="
cd /root/workspace/security && terraform state list
```

每个层只包含自己的资源。改网络层不会刷新 DynamoDB 的状态，改数据层不需要 VPC 的写锁。

## 验证 Terragrunt 依赖

```bash
cd /root/workspace
terragrunt run-all plan --terragrunt-non-interactive -parallelism=2
```

所有层：0 to add, 0 to change, 0 to destroy。

## 第一步的五个问题，现在解决了几个？

| 问题 | Step 4（模块化） | Step 5（状态隔离） |
|------|----------------|------------------|
| 慢 | plan 仍刷新所有资源 | 每层只刷新自己的资源 |
| 不安全 | 一个 state 权限全有 | 每层独立 state，可分别授权 |
| 高风险 | 误操作可能波及全局 | 爆炸半径限制在单层 |
| 难理解 | 模块已解决 | 模块已解决 |
| 难测试 | 仍需全量 init | 单层独立 plan/apply |
