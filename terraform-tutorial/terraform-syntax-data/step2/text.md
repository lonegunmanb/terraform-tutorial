# 第二步：data + resource 协作 — 查询已有资源

在实际项目中，数据源最常见的用途是**查询已有资源的信息**。本步模拟一个典型场景：配置桶和事件队列已经存在（由 setup.tf 创建），应用代码通过 data 查询它们的属性，然后基于这些信息创建新资源。

## 查看代码

这一步有两个文件，它们在同一个目录中，共同构成一个 Terraform 配置：

```bash
cd /root/workspace/step2
cat setup.tf
```

setup.tf 创建了"已有"的基础设施：
- 一个名为 `shared-config-bucket` 的 S3 配置桶，包含应用配置文件
- 一个名为 `shared-events-queue` 的 SQS 事件队列

```bash
cat main.tf
```

main.tf 展示了数据源的典型使用模式：

- `data "aws_s3_bucket" "config"` — 查询配置桶的详细信息（ARN、区域等）
- `data "aws_sqs_queue" "events"` — 查询事件队列的 URL 和 ARN
- 新创建的资源引用了 data 查询到的属性

注意 data 块中的查询参数引用了同一配置中的 resource 属性（如 `aws_s3_bucket.shared_config.id`），这意味着这些数据源会在 apply 阶段——资源创建之后——才执行读取。

## 初始化并执行

```bash
terraform init
terraform plan
```

观察 plan 输出中数据源的行为：
- `data.aws_s3_bucket.config` 和 `data.aws_sqs_queue.events` 标记为 `read during apply`
- 因为它们依赖尚未创建的 resource，无法在 plan 阶段读取
- 引用这些 data 的属性显示为 `(known after apply)`

```bash
terraform apply -auto-approve
```

## 验证数据源查询结果

```bash
# 查看 data 查询到的配置桶 ARN
terraform output config_bucket_arn

# 查看 data 查询到的事件队列 URL 和 ARN
terraform output events_queue_arn
terraform output events_queue_url
```

对比 data 查询到的信息和直接通过 AWS CLI 查询的结果：

```bash
# 用 AWS CLI 查看同一个桶
awslocal s3api get-bucket-location --bucket shared-config-bucket

# 用 AWS CLI 查看同一个队列
awslocal sqs get-queue-url --queue-name shared-events-queue
awslocal sqs get-queue-attributes --queue-url $(terraform output -raw events_queue_url) --attribute-names QueueArn
```

数据源返回的信息与 AWS CLI 查询的结果一致——data 只是 Terraform 中查询已有信息的方式。

## 查看 data 如何被其他资源使用

```bash
# 查看日志桶中的来源信息文件
awslocal s3 cp s3://app-logs-bucket/source-info.json - | python3 -m json.tool
```

这个文件中的 ARN 和 URL**都来自 data 查询**，不是硬编码的。这就是 data 的核心价值——让你的代码动态地引用已有基础设施的属性，而不是写死字符串。

## 对比 data 引用和直接引用

你可能注意到，在 main.tf 中我们既直接引用了 resource 属性（如 `aws_s3_bucket.shared_config.id`），也通过 data 查询了同一个资源（`data.aws_s3_bucket.config.arn`）。

在**同一个模块**中这两种方式都可以。那什么时候必须用 data？

- 资源不在当前 Terraform 代码中管理时（由其他团队/代码创建）
- 需要查询当前代码中不存在的属性时
- 跨状态文件引用时

在实际项目中，data 查询的通常是**别人管理的**资源——你不控制它的生命周期，但需要它的信息。

## 清理

```bash
terraform destroy -auto-approve
```

## 关键点

- data 最常见的用途是查询已经存在的资源信息
- 当 data 的查询参数依赖未创建的资源时，读取会推迟到 apply 阶段
- data 让代码动态引用已有基础设施，避免硬编码
- 在同一模块内可以直接引用 resource 属性；data 更适合查询当前代码未管理的外部资源

完成后继续下一步。
