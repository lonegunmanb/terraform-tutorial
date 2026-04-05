# 第二步：多文件模块 — .tf 文件的合并规则

在这一步中，你将理解 Terraform 模块中多个 .tf 文件的合并行为，以及什么情况会导致冲突。

## 查看多文件结构

```bash
cd /root/workspace/step2
ls *.tf
```

你会看到五个 .tf 文件：

```
buckets.tf    — 数据桶资源
logs.tf       — 日志桶资源
outputs.tf    — 输出值
provider.tf   — terraform 块和 provider 配置
variables.tf  — 输入变量
```

这些文件共同构成**一个模块**。Terraform 加载模块时，会读取目录下所有 .tf 文件，将它们的内容合并为一个整体——就像把所有文件的内容拼接到一个大文件中一样。

逐个查看文件内容：

```bash
echo "=== provider.tf ==="
cat provider.tf

echo "=== variables.tf ==="
cat variables.tf

echo "=== buckets.tf ==="
cat buckets.tf

echo "=== logs.tf ==="
cat logs.tf

echo "=== outputs.tf ==="
cat outputs.tf
```

注意：
- buckets.tf 中的资源引用了 variables.tf 中定义的 var.project
- logs.tf 中的资源也引用了同一个变量
- outputs.tf 中的输出引用了 buckets.tf 和 logs.tf 中的资源

**跨文件引用不需要任何 import 或 include 语句**——在同一个模块（目录）内，所有 .tf 文件中的定义天然可见。

## 执行验证

```bash
terraform init
terraform plan
```

Terraform 把五个文件合并处理，计划创建两个 S3 桶。

```bash
terraform apply -auto-approve
awslocal s3 ls
```

## 制造重复定义冲突

现在试试在另一个文件中重复定义同名资源，看看会发生什么：

```bash
cat > extra.tf <<'EOF'
resource "aws_s3_bucket" "data" {
  bucket = "another-data-bucket"
}
EOF
```

```bash
terraform plan
```

Terraform 会报错：

```
Error: Duplicate resource "aws_s3_bucket" configuration
```

因为 buckets.tf 中已经定义了 aws_s3_bucket.data，extra.tf 又定义了一个同名资源——合并后出现了重复，这是不允许的。

同样的规则适用于所有顶层定义：variable、output、locals、data 等都不能重名。

删除冲突文件：

```bash
rm extra.tf
```

## 重复变量定义

再试试重复定义变量：

```bash
cat > extra.tf <<'EOF'
variable "project" {
  type    = string
  default = "other"
}
EOF
```

```bash
terraform plan
```

报错：

```
Error: Duplicate variable declaration
```

variables.tf 中已有 variable "project"，不能在另一个文件中重复声明。

```bash
rm extra.tf
```

## 文件名不影响行为

文件名纯粹是组织约定。试试把所有内容合并到一个文件中：

```bash
cat provider.tf variables.tf buckets.tf logs.tf outputs.tf > all-in-one.tf
rm provider.tf variables.tf buckets.tf logs.tf outputs.tf
```

```bash
terraform plan
```

Terraform 显示 "No changes"——无论代码分散在多个文件还是集中在一个文件，对 Terraform 来说完全等价。

## 清理

```bash
terraform destroy -auto-approve
```

## 关键点

- Terraform 将目录下所有 .tf 文件合并为一个整体
- 跨文件引用不需要 import 语句，同目录内天然可见
- 同一模块内不能有重名的 resource、variable、output 等顶层定义
- 文件名不影响行为，只是团队约定的组织方式

完成后继续下一步。
