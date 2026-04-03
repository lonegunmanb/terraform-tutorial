# 第三步：lifecycle、dynamic 块与 provisioner

在这一步中，你将构建一个"事件驱动的通知系统"，学习资源的生命周期管理、动态块和本地执行器。

## 查看代码

```bash
cd /root/workspace/step3
cat main.tf
```

代码展示了三大主题：

### lifecycle — 自定义生命周期行为

代码中使用了三种 lifecycle 设置：

**prevent_destroy** — 防止资源被意外删除：

```hcl
lifecycle {
  prevent_destroy = true  # 尝试删除时 Terraform 会报错
}
```

**ignore_changes** — 忽略外部系统对某些属性的修改：

```hcl
lifecycle {
  ignore_changes = [tags]  # 标签变更不会触发更新
}
```

**create_before_destroy** — 替换时先创建新的再删除旧的：

```hcl
lifecycle {
  create_before_destroy = true  # 保持服务可用性
}
```

### dynamic 块 — 动态生成嵌套块

```hcl
dynamic "attribute" {
  for_each = var.extra_attributes
  content {
    name = attribute.value.name
    type = attribute.value.type
  }
}
```

避免了重复编写多个 attribute 块，由变量驱动动态生成。

### provisioner — 在资源创建/销毁时执行操作

```hcl
provisioner "local-exec" {
  command = "echo 'Bucket created' >> deploy.log"
}
```

## 初始化并执行

```bash
terraform init
terraform plan
```

观察 plan 输出，特别注意：
- events-table 有 3 个 attribute 块，由 dynamic 块生成
- SNS topic 有 3 个 SQS 订阅，由 for_each 生成
- report 桶配置了 provisioner

```bash
terraform apply -auto-approve
```

## 验证 dynamic 块

```bash
# 查看 events-table 的属性定义
awslocal dynamodb describe-table --table-name events-table --query 'Table.AttributeDefinitions'
```

你会看到 3 个属性（user_id、event_type、score），它们由 dynamic 块根据变量自动生成。

## 验证 SNS + SQS 扇出

```bash
# 查看 SNS 主题
awslocal sns list-topics

# 查看订阅列表
awslocal sns list-subscriptions

# 向主题发送一条消息
awslocal sns publish --topic-arn $(terraform output -raw topic_arn) --message "Test alert"

# 从其中一个队列接收消息
awslocal sqs receive-message --queue-url $(terraform output -json subscriber_queues | python3 -c "import sys,json; print(list(json.load(sys.stdin).values())[0])")
```

消息被"扇出"到所有订阅队列，这是事件驱动架构的经典模式。

## 验证 provisioner

```bash
# 查看 provisioner 创建的日志
cat /root/workspace/step3/deploy.log
```

你会看到桶创建时记录的日志行。

## 体验 lifecycle 行为

### ignore_changes

给 uploads 桶添加一个标签（模拟外部系统修改）：

```bash
awslocal s3api put-bucket-tagging --bucket user-uploads-bucket --tagging 'TagSet=[{Key=ExternalTag,Value=added-by-ci}]'
```

然后运行 plan：

```bash
terraform plan
```

由于配置了 `ignore_changes = [tags]`，Terraform 不会尝试覆盖外部添加的标签。

### prevent_destroy

尝试删除 audit_log 表（代码中 prevent_destroy 设为 false 用于实验）。如果你将其改为 true：

```bash
sed -i 's/prevent_destroy = false/prevent_destroy = true/' main.tf
terraform apply -auto-approve
```

然后尝试注释掉 audit_log 资源并运行 plan，Terraform 会报错拒绝删除。

还原修改：

```bash
sed -i 's/prevent_destroy = true/prevent_destroy = false/' main.tf
```

## 清理

在所有步骤完成后，可以清理创建的资源：

```bash
terraform destroy -auto-approve
```

## 关键点

- lifecycle 的三个常用设置：prevent_destroy（防删除）、ignore_changes（忽略变更）、create_before_destroy（先建后删）
- dynamic 块通过遍历集合动态生成重复的嵌套块，适度使用
- provisioner 是"逃生舱"，优先使用 Provider 原生功能
- local-exec provisioner 在运行 Terraform 的机器上执行命令
- provisioner 支持 when = destroy 在资源销毁时执行清理操作

恭喜你完成了资源的学习！
