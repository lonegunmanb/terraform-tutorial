# 第二步：拆分小模块——职责分离

## 查看拆分后的结构

```bash
cd /root/workspace/step2
find . -name "*.tf" | sort
```

你会看到以下目录结构：

```
./main.tf
./variables.tf
./outputs.tf
./modules/storage/main.tf
./modules/storage/variables.tf
./modules/storage/outputs.tf
./modules/queue/main.tf
./modules/queue/variables.tf
./modules/queue/outputs.tf
./modules/database/main.tf
./modules/database/variables.tf
./modules/database/outputs.tf
```

每个子模块只负责一件事—— storage 只管 S3，queue 只管 SQS，database 只管 DynamoDB。

## 读懂每个模块的接口

查看 storage 模块：

```bash
cat modules/storage/variables.tf
cat modules/storage/outputs.tf
```

模块的 `variable` 是它的**输入接口**，`output` 是它的**输出接口**。调用方完全不需要知道模块内部的实现细节——这正是封装的价值。

## 查看根模块如何组合

```bash
cat main.tf
```

注意这几行：

```hcl
module "storage" {
  source      = "./modules/storage"
  bucket_name = "${var.app_name}-${var.environment}-config"
}

resource "aws_iam_policy" "app_reader" {
  policy = jsonencode({
    Statement = [{
      Resource = module.storage.bucket_arn  # 使用 storage 模块的输出
    }]
  })
}
```

`module.storage.bucket_arn` 是**函数组合**的体现：把 storage 模块的输出作为 IAM 策略的输入。整个系统是各模块输入/输出的网络，而不是硬编码的耦合。

## 部署完整的系统

```bash
terraform init
terraform plan
```

观察 `plan` 输出——现在你能清楚地看到每个模块负责哪些资源了。

```bash
terraform apply -auto-approve
```

## 验证模块化部署成功

```bash
terraform state list
```

注意资源地址的格式：
- `module.storage.aws_s3_bucket.this`
- `module.queue.aws_sqs_queue.this`
- `module.database.aws_dynamodb_table.this`

层次化的资源地址，清楚表达了"谁属于谁"。

## 体会权限边界的变化

在真实的 AWS 环境里，你现在可以为不同的团队授予不同模块的操作权限：
- 存储团队：只能操作 `module.storage` 相关资源
- 消息团队：只能操作 `module.queue` 相关资源

```bash
# 查看队列相关的输出
terraform output notification_queue_url
terraform output audit_table_name
```

## 模块拆分后的对比

| 维度 | 单体 | 小模块 |
|------|------|-------|
| 定位一个资源 | 在 100+ 行里 grep | 直接进对应模块目录 |
| 修改影响范围 | 整个文件 | 单个模块 |
| 权限控制 | 全有或全无 | 按模块精细控制 |
| 团队协作 | 冲突频繁 | 各改各的模块 |
| 测试 | 全量 apply | 单模块独立测试 |

下一步，我们把自制的 S3 模块替换成来自社区的高质量模块。
