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

- `bucket_has_tags` 的断言失败，因为 S3 桶没有标签——但这只是一个**警告**（Warning），不是错误
- `queue_timeout_reasonable` 的两个断言都通过，没有任何输出
- `website_health` 中的有限作用域数据源标记为 `read during apply`（因为它依赖尚未创建的资源）

**关键观察：尽管 check 断言失败了，plan 仍然正常完成！** 如果把同样的条件写在 postcondition 里，Terraform 会报错并中止操作。

现在执行 apply：

```bash
terraform apply -auto-approve
```

观察 apply 的输出：

- 三个资源成功创建
- `bucket_has_tags` 再次输出警告——桶确实没有标签
- `website_health` 检查执行了 HTTP 请求，观察它的结果

**注意 check 块的警告不影响任何资源的创建和输出。** 这就是 check 与 postcondition 的核心区别。

## 修复 check 警告

现在让我们给 S3 桶添加标签来修复 `bucket_has_tags` 的警告。

用编辑器打开 main.tf，找到 `aws_s3_bucket` 资源，添加 tags 参数：

```bash
cat > /tmp/fix.py << 'PYEOF'
import re
with open("main.tf", "r") as f:
    content = f.read()
content = content.replace(
    'resource "aws_s3_bucket" "website" {\n  bucket = "demo-website-bucket"\n}',
    'resource "aws_s3_bucket" "website" {\n  bucket = "demo-website-bucket"\n  tags = {\n    ManagedBy = "terraform"\n  }\n}'
)
with open("main.tf", "w") as f:
    f.write(content)
PYEOF
python3 /tmp/fix.py
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
