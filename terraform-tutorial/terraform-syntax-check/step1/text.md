# 第一步：check 块演示 — 健康检查与断言

在这一步中，你将观察 check 块的行为——它的断言失败只产生警告，不会阻止 Terraform 操作。

## 查看代码

```bash
cd /root/workspace/step1
cat main.tf
```

这份代码定义了三个资源和三个 check 块：

**资源：**
- 一个 S3 桶 `demo-website-bucket`
- 一个 S3 对象 `index.html`
- 一个 SQS 队列 `demo-notifications`

**check 块：**
1. `bucket_has_tags` — 检查 S3 桶是否设置了标签（我们故意没有添加标签，这个检查**会失败**）
2. `queue_timeout_reasonable` — 检查 SQS 队列的可见性超时是否在合理范围（30-300 秒）内（这个检查**会通过**）
3. `website_health` — 使用**有限作用域数据源**通过 HTTP 请求验证网站是否可访问

## 初始化并执行

环境已为你预初始化了 step1 目录。直接运行 plan：

```bash
terraform plan
```

观察 plan 输出。注意 check 块的警告信息：

- `bucket_has_tags` 显示 `Check block assertion known after apply`——因为 `tags_all` 是计算属性，plan 阶段资源尚未创建，无法确定其值
- `queue_timeout_reasonable` 的两个断言同样等待 apply 后才能评估
- `website_health` 中的有限作用域数据源也标记为 `known after apply`（因为它依赖尚未创建的资源）

**关键观察：即使 check 块无法在 plan 阶段评估，plan 仍然正常完成！** Terraform 只是输出警告，提示结果将在 apply 后才知晓。

现在执行 apply：

```bash
terraform apply -auto-approve
```

观察 apply 的输出：

- 三个资源成功创建
- `bucket_has_tags` 的断言现在被真正评估——因为桶没有标签，断言失败，输出**警告**
- `website_health` 检查执行了 HTTP 请求，观察它的结果

**注意 check 块的警告不影响任何资源的创建和输出。** 这就是 check 与 postcondition 的核心区别——如果把同样的条件写在 postcondition 里，Terraform 会报错并中止操作。

## 修复 check 警告

现在让我们给 S3 桶添加标签来修复 `bucket_has_tags` 的警告。

用编辑器打开 main.tf，找到 `aws_s3_bucket` 资源块，添加 `tags` 参数，改为：

```hcl
resource "aws_s3_bucket" "website" {
  bucket = "demo-website-bucket"
  tags = {
    ManagedBy = "terraform"
  }
}
```

再次执行 apply：

```bash
terraform apply -auto-approve
```

观察输出变化：
- `bucket_has_tags` 的警告消失了——标签已设置，断言通过
- 其他 check 保持不变

## 对比 check 与 postcondition

如果你好奇"如果把 check 改成 postcondition 会怎样"——postcondition 写在资源的 lifecycle 块内，失败时会**报错并阻止操作**：

```
# postcondition 失败时的输出：
# Error: Resource postcondition failed
#   ...
# S3 桶没有设置任何标签。
```

而 check 失败时：

```
# check 失败时的输出：
# Warning: Check block assertion failed
#   ...
# S3 桶没有设置任何标签，建议添加 ManagedBy 标签。
```

两者的语法几乎一样，但行为截然不同：一个阻塞操作，一个只是提醒。

## 清理

```bash
terraform destroy -auto-approve
```

## 关键点

- check 块在 plan 和 apply 的**最后一步**执行
- assert 断言失败产生**警告**而非错误，不阻塞操作
- check 内可以定义**有限作用域数据源**，该数据源只能在 check 块内引用
- 有限作用域数据源的错误也会降级为警告
- check 不支持 count、for_each 等元参数
- 当有限作用域数据源依赖尚未创建的资源时，用 depends_on 避免无意义的警告

完成后继续下一步。
