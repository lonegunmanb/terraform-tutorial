# 第五步：terraform force-unlock — 解除卡死的状态锁

## 背景

Terraform 在执行 plan / apply 等操作前，会向 Backend 申请一把**状态锁**，防止多进程并发写入。Backend 不同，锁的存储方式也不同：

- 本地 backend：在工作目录写入 `terraform.tfstate.lock.info` 文件
- S3 backend（配合 DynamoDB）：在 DynamoDB 表中写入一条锁记录

当进程意外崩溃（Ctrl+C、断网、OOM kill…），锁记录可能残留，导致后续所有 Terraform 操作都被阻断。这时需要用 `terraform force-unlock` 手动释放。

本步骤使用预配置的 s3-demo 工作目录演示，该目录使用 S3 + DynamoDB backend（均由 LocalStack 模拟）。

## 进入演示工作目录

```bash
cd /root/workspace/s3-demo
```

查看该目录已有的 Terraform 状态（background 已预先 apply）：

```bash
terraform show
```

## 模拟孤儿锁：向 DynamoDB 注入假锁记录

真实场景中孤儿锁由崩溃的进程留下。这里用 awslocal 直接向 DynamoDB 写入一条带有固定 Lock ID 的锁记录，模拟这一情况：

```bash
cat > /tmp/lock.json << 'EOF'
{
  "LockID": {"S": "terraform-state/demo/terraform.tfstate"},
  "Info":   {"S": "{\"ID\":\"aabb1234-dead-beef-cafe-001122334455\",\"Operation\":\"OperationTypeApply\",\"Info\":\"\",\"Who\":\"ghost@killercoda\",\"Version\":\"1.11.0\",\"Created\":\"2026-04-08T12:00:00.000000Z\",\"Path\":\"demo/terraform.tfstate\"}"}
}
EOF

awslocal dynamodb put-item \
  --table-name terraform-lock \
  --region us-east-1 \
  --item file:///tmp/lock.json
```

确认锁记录已写入：

```bash
awslocal dynamodb get-item \
  --table-name terraform-lock \
  --region us-east-1 \
  --key '{"LockID": {"S": "terraform-state/demo/terraform.tfstate"}}'
```

## 观察锁阻断错误

尝试执行 plan，Terraform 会向 DynamoDB 查询锁状态，发现写入失败并返回错误：

```bash
terraform plan
```

你会看到类似输出：

```text
╷
│ Error: Error acquiring the state lock
│
│ Error message: ConditionalCheckFailedException: ...
│
│ Lock Info:
│   ID:        aabb1234-dead-beef-cafe-001122334455
│   Path:      demo/terraform.tfstate
│   Operation: OperationTypeApply
│   Who:       ghost@killercoda
│   Version:   1.11.0
│   Created:   2026-04-08 12:00:00 +0000 UTC
│   Info:
╵
```

错误信息中明确给出了 Lock ID，这正是解锁所需的参数。

## 运行 terraform force-unlock

使用错误信息中的 Lock ID 解锁：

```bash
terraform force-unlock aabb1234-dead-beef-cafe-001122334455
```

Terraform 会要求输入 yes 确认，输入后成功输出：

```text
Terraform state has been successfully unlocked!
```

## 确认 DynamoDB 中锁记录已清除

```bash
awslocal dynamodb get-item \
  --table-name terraform-lock \
  --region us-east-1 \
  --key '{"LockID": {"S": "terraform-state/demo/terraform.tfstate"}}'
```

返回空结果（无 Item 字段）说明锁已释放。

## 再次运行 plan 验证解锁生效

```bash
terraform plan
```

这次应该正常计划，不再报锁错误。

> 只有在确认没有其他 Terraform 进程正在运行时才使用 force-unlock，否则可能导致并发写入损坏状态文件。
