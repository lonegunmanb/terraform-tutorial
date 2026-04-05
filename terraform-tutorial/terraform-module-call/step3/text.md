# 第三步：count、for_each 与 depends_on

在这一步中，你将学习如何使用 count、for_each 和 depends_on 元参数——前两者用于批量创建模块实例，depends_on 用于声明模块间的隐式依赖。

## 查看代码

```bash
cd /root/workspace/step3
cat main.tf
```

这段代码同时演示了 count 和 for_each 两种批量调用方式。

## 使用 count 批量调用

```hcl
module "buckets_count" {
  source      = "../modules/s3-bucket"
  count       = length(var.bucket_names)
  bucket_name = "count-${var.bucket_names[count.index]}"
  tags = {
    Index = count.index
  }
}
```

count 的工作方式：
- count = 3 会创建 3 个模块实例
- 每个实例通过 count.index 获取索引（0、1、2）
- 实例地址为 module.buckets_count[0]、module.buckets_count[1] 等

## 初始化并执行 count 示例

```bash
terraform init
terraform plan
```

观察 plan 输出中的资源地址：

```
module.buckets_count[0].aws_s3_bucket.this
module.buckets_count[1].aws_s3_bucket.this
module.buckets_count[2].aws_s3_bucket.this
```

```bash
terraform apply -auto-approve
```

查看输出：

```bash
terraform output count_bucket_ids
```

## 使用 for_each 批量调用

```hcl
module "env_buckets" {
  source      = "../modules/s3-bucket"
  for_each    = var.environments
  bucket_name = "app-${each.value.suffix}"
  tags        = each.value.tags
}
```

for_each 的工作方式：
- for_each 接受 map 或 set 类型
- 每个实例通过 each.key 获取键名，each.value 获取值
- 实例地址为 module.env_buckets["dev"]、module.env_buckets["prod"] 等

查看 for_each 的输出：

```bash
terraform output env_bucket_ids
```

输出是一个 map，键名就是 for_each 的键：

```
{
  "dev"     = "app-dev"
  "prod"    = "app-prod"
  "staging" = "app-staging"
}
```

## count 与 for_each 的区别

查看状态中的资源地址：

```bash
terraform state list
```

对比两种方式的地址：

- count 使用**数字索引**：module.buckets_count[0]
- for_each 使用**字符串键**：module.env_buckets["dev"]

这个区别在增删元素时非常重要。现在从 count 的列表中间删除 beta，观察会发生什么：

```bash
sed -i 's/"alpha", "beta", "gamma"/"alpha", "gamma"/' main.tf
```

确认修改生效：

```bash
grep bucket_names -A3 main.tf
```

现在运行 plan 看看 Terraform 怎么处理：

```bash
terraform plan
```

观察输出——Terraform 计划：
- 替换 module.buckets_count[1]（把 count-beta 改成 count-gamma）——桶名变了，必须销毁重建
- 销毁 module.buckets_count[2]（索引 2 不再存在）

结果是 1 to add, 0 to change, 2 to destroy。

这就是 count 的索引偏移问题：删除中间的 beta 后，gamma 从索引 2 滑到了索引 1。索引 1 原来对应 count-beta，现在要变成 count-gamma——桶名变了，必须销毁重建。而索引 2 不再存在，也要被销毁。

你只是想删除一个桶，却导致了两个桶被影响。

恢复原始列表：

```bash
sed -i 's/"alpha", "gamma"/"alpha", "beta", "gamma"/' main.tf
```

而 for_each 使用字符串键，不存在这个问题。试试删除 staging 环境，只保留 dev 和 prod：

```bash
terraform plan -var='environments={"dev":{"suffix":"dev","tags":{"Environment":"dev"}},"prod":{"suffix":"prod","tags":{"Environment":"prod"}}}' 2>&1 | grep -E "will be|Plan:"
```

观察输出——Terraform 只会销毁 module.env_buckets["staging"]，dev 和 prod 完全不受影响，因为它们的键没有变化。

## 最佳实践

- 当实例有明确的标识（名称、环境等）时，优先使用 for_each
- 当只需要指定数量、且顺序不重要时，可以使用 count
- count = 0 或 for_each = {} 可以条件性地禁用模块

## module 级别的 depends_on

Terraform 通常能自动推断资源之间的依赖关系——当你在参数中引用了另一个资源的属性时，Terraform 就知道要先创建被引用的资源。

但有时候依赖关系是**隐式的**，代码中没有直接引用，Terraform 无法自动推断。这时就需要 depends_on。

module 级别的 depends_on 有一个关键特点：**module 是一个整体**。无论模块内有多少资源，depends_on 都把整个模块当作一个原子单元来处理。具体来说有三种场景：

1. **module depends_on 资源**：除非该资源创建完成，否则模块内**所有资源和 data** 都被阻塞
2. **资源 depends_on module**：除非模块内**所有资源**都创建完成，才会轮到该资源
3. **module depends_on module**：除非前置模块的**所有资源**都创建完成，否则后置模块内**所有资源**都被阻塞

动手验证。我们已经为你准备了一个 dual-bucket 模块（包含 primary 和 replica 两个桶），用它来观察执行顺序：

```bash
echo "=== dual-bucket 模块 ==="
cat ../modules/dual-bucket/main.tf
```

在 main.tf 末尾添加三个场景的演示代码：

```bash
cat >> main.tf <<'EOF'

# ── depends_on 演示 ──

# 场景1: module depends_on 资源
# config 桶必须先创建完，app 模块的所有资源才开始
resource "aws_s3_bucket" "config" {
  bucket = "dep-config-store"
}

module "app" {
  source     = "../modules/dual-bucket"
  prefix     = "dep-app"
  depends_on = [aws_s3_bucket.config]
}

# 场景2: 资源 depends_on module
# app 模块的所有资源必须全部创建完，finalizer 才开始
resource "aws_s3_bucket" "finalizer" {
  bucket     = "dep-finalizer"
  depends_on = [module.app]
}

# 场景3: module depends_on module
# app 模块的所有资源必须全部创建完，downstream 模块的所有资源才开始
module "downstream" {
  source     = "../modules/dual-bucket"
  prefix     = "dep-downstream"
  depends_on = [module.app]
}
EOF
```

```bash
terraform init
terraform apply -auto-approve 2>&1 | grep -E "Creating|Creation complete"
```

观察输出中的执行顺序：

```
aws_s3_bucket.config: Creating...
aws_s3_bucket.config: Creation complete after 1s
module.app.aws_s3_bucket.primary: Creating...
module.app.aws_s3_bucket.replica: Creating...
module.app.aws_s3_bucket.primary: Creation complete after 0s
module.app.aws_s3_bucket.replica: Creation complete after 0s
module.downstream.aws_s3_bucket.primary: Creating...
module.downstream.aws_s3_bucket.replica: Creating...
aws_s3_bucket.finalizer: Creating...
...
```

逐一对照：

- **config 先完成** → app 模块的 primary 和 replica 才开始（场景1：module depends_on 资源）
- **app 的 primary 和 replica 都完成** → finalizer 才开始（场景2：资源 depends_on module）
- **app 的 primary 和 replica 都完成** → downstream 的 primary 和 replica 才开始（场景3：module depends_on module）

注意 finalizer 和 downstream 都要等 app 模块内**所有**资源完成——不是只等其中一个。这就是 module 级别 depends_on 的整体性。

清理刚添加的代码：

```bash
head -n 79 main.tf > main.tf.tmp && mv main.tf.tmp main.tf
terraform destroy -auto-approve
```

depends_on 的使用原则：
- 只在 Terraform 无法自动推断依赖时使用——如果能通过引用表达式（如 bucket = module.xxx.id）表达依赖，就不需要 depends_on
- depends_on 会导致 Terraform 生成更保守的执行计划，更多值变成 (known after apply)
- module 级别的 depends_on 影响范围大——整个模块的所有资源和 data 都会被阻塞或等待

## 清理

```bash
terraform destroy -auto-approve
```

## 关键点

- count 通过数字索引批量创建模块实例
- for_each 通过字符串键批量创建模块实例
- for_each 在增删元素时更稳定，不会引起索引偏移
- 引用 count 实例：module.name[index]，输出用 [*] 展开
- 引用 for_each 实例：module.name["key"]，输出用 for 表达式转换
- depends_on 用于声明隐式依赖，只在 Terraform 无法自动推断时使用
- module 级别的 depends_on 会影响模块内所有资源的执行顺序

完成后继续下一步。
