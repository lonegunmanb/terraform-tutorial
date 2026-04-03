# 第二步：count 与 for_each — 批量创建资源

在这一步中，你将构建一个"微服务消息系统"，学习使用 count 和 for_each 批量创建资源，以及 depends_on 显式依赖。

## 查看代码

```bash
cd /root/workspace/step2
cat main.tf
```

代码展示了三种批量创建资源的模式：

### count：创建相似的资源

```hcl
resource "aws_sqs_queue" "worker" {
  count = var.queue_count
  name  = "worker-queue-${count.index}"
}
```

- `count = 3` 创建 3 个 SQS 队列
- `count.index` 是当前实例的索引（0, 1, 2）
- 通过 `aws_sqs_queue.worker[0]` 或 `aws_sqs_queue.worker[*].url` 访问

### for_each + map：每个实例有不同配置

```hcl
resource "aws_dynamodb_table" "service" {
  for_each = var.tables
  name     = "${each.key}-table"
  hash_key = each.value.hash_key
}
```

- `for_each` 遍历 map，每个键值对创建一个表
- `each.key` 是键（users/orders/products），`each.value` 是值
- 通过 `aws_dynamodb_table.service["users"]` 访问

### for_each + set：从列表创建资源

```hcl
resource "aws_s3_bucket" "data" {
  for_each = toset(var.bucket_names)
  bucket   = "myapp-${each.key}"
}
```

- `toset()` 将列表转换为集合
- 在 set 中，`each.key` 和 `each.value` 相同

## 初始化并执行

```bash
terraform init
terraform plan
```

观察 plan 输出中资源的标识方式：
- count 资源用数字索引：`aws_sqs_queue.worker[0]`、`aws_sqs_queue.worker[1]`
- for_each 资源用键名：`aws_dynamodb_table.service["users"]`、`aws_s3_bucket.data["raw-data"]`

```bash
terraform apply -auto-approve
```

## 验证资源

```bash
# 查看所有 SQS 队列
awslocal sqs list-queues

# 查看所有 DynamoDB 表
awslocal dynamodb list-tables

# 查看 users 表的结构
awslocal dynamodb describe-table --table-name users-table --query 'Table.{Name:TableName,HashKey:KeySchema[0].AttributeName,RangeKey:KeySchema[1].AttributeName}'

# 查看所有 S3 桶
awslocal s3 ls
```

## count vs for_each 对比实验

代码中已经准备了一个对比实验：同一个 `subnet_ids` 列表，分别被 count 和 for_each 引用创建 SQS 队列。

先看看当前状态，确认 6 个队列都已创建（count 3 个 + for_each 3 个）：

```bash
terraform output count_demo_names
terraform output foreach_demo_names
```

现在，从列表中间删除 subnet-bbb，观察 count 和 for_each 的不同反应：

```bash
terraform plan -var='subnet_ids=["subnet-aaa","subnet-ccc"]'
```

仔细观察 plan 输出，你会看到截然不同的行为：

**count 部分（`count_demo`）— 2 个变更：**
- `count_demo[1]` 要**替换**（must be replaced）— 从 count-subnet-bbb **改名**为 count-subnet-ccc，由于队列名是不可变属性，必须先删后建
- `count_demo[2]` 要**销毁**（destroy）

**for_each 部分（`foreach_demo`）— 仅 1 个变更：**
- `foreach_demo["subnet-bbb"]` 要**销毁**（destroy）
- 其他两个完全不受影响

这就是 count 的陷阱：资源按数字索引绑定。删除中间元素后，索引 1 原来对应 subnet-bbb，现在对应 subnet-ccc，导致后续所有资源都发生移位。实际效果是 subnet-ccc 的队列被**改名**，然后**多删一个**。

而 for_each 用有意义的键（subnet-aaa、subnet-bbb、subnet-ccc）标识每个资源，删除 subnet-bbb 只会精确地销毁那一个，其他资源完全不动。

## depends_on：隐式 vs 显式依赖

代码中有两组依赖关系对比：

### 隐式依赖（不需要 depends_on）

`main_queue` 的 `redrive_policy` 引用了 `aws_sqs_queue.dead_letter.arn`，Terraform 通过这个引用**自动推导**出 dead_letter 必须先创建。查看代码确认没有 `depends_on`：

```bash
grep -A5 'main_queue' main.tf | head -10
```

### 显式依赖（必须用 depends_on）

`app_queue` 运行时需要 `setup_step`（一个初始化脚本）已完成，但代码中**没有引用** `setup_step` 的任何属性——Terraform 无法自动推导这个依赖关系。如果去掉 `depends_on`，Terraform 可能并行执行两者，导致初始化未完成就创建了队列。

用 `terraform graph` 查看依赖图中的差异：

```bash
terraform graph | grep -E 'main_queue|dead_letter|app_queue|setup_step'
```

你会看到：
- `main_queue` -> `dead_letter`：**隐式依赖**（来自 ARN 引用）
- `app_queue` -> `setup_step`：**显式依赖**（来自 depends_on）

规则：能用隐式依赖（属性引用）就不要用 `depends_on`。只有当依赖关系无法通过代码引用表达时，才需要 `depends_on`。

## 清理

进入下一步之前，先清理本步创建的所有资源：

```bash
terraform destroy -auto-approve
```

## 关键点

- count 适合创建几乎完全相同的资源，用数字索引区分
- for_each 适合每个实例有不同配置的场景，用键标识
- for_each 比 count 更稳定 — 删除集合中的元素不会影响其他资源
- depends_on 只在隐式依赖无法推导时使用

完成后继续下一步。
