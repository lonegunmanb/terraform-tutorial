# 第二步：状态操作 (mv / rm)

### 重命名资源 (state mv)

假设你想把 `aws_s3_bucket.logs` 重命名为 `aws_s3_bucket.application_logs`：

首先在 `main.tf` 中将 `resource "aws_s3_bucket" "logs"` 改为 `resource "aws_s3_bucket" "application_logs"`（同时更新 output 中的引用）。

然后执行状态移动，告诉 Terraform "这不是删旧建新，而是改名"：

```bash
terraform state mv aws_s3_bucket.logs aws_s3_bucket.application_logs
```

验证：

```bash
terraform state list
terraform plan
```

`plan` 应该显示 **No changes**——证明状态移动成功，没有触发资源重建。

### 从状态中移除 (state rm)

如果你想让 Terraform "忘记"某个资源（但不销毁真实资源）：

```bash
terraform state rm aws_dynamodb_table.locks
```

再次 plan 看看会发生什么：

```bash
terraform plan
```

Terraform 会认为这个表需要**重新创建**，因为状态里已经没有它了。

> ⚠️ `state rm` 不会销毁真实资源，只是断开了 Terraform 的追踪。
