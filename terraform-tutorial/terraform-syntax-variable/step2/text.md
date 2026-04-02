# 第二步：断言校验

validation 块允许对变量值进行自定义校验，在赋值不合法时提前报错。

## 查看示例代码

```bash
cd /root/workspace/step2
cat main.tf
```

### validation 块的结构

每个 validation 块包含两个参数：

| 参数 | 作用 |
|------|------|
| condition | 布尔表达式，为 true 时校验通过 |
| error_message | 校验失败时显示的错误信息 |

### 三种常见校验模式

**1. 数值范围校验**

```hcl
validation {
  condition     = var.instance_count >= 1 && var.instance_count <= 10
  error_message = "必须在 1 到 10 之间。"
}
```

**2. 正则格式校验（can + regex）**

```hcl
validation {
  condition     = can(regex("^ami-", var.image_id))
  error_message = "必须以 ami- 开头。"
}
```

can 函数会捕获 regex 的执行错误。如果正则不匹配，regex 抛错，can 返回 false。

**3. 枚举值校验（contains）**

```hcl
validation {
  condition     = contains(["dev", "staging", "prod"], var.environment)
  error_message = "必须是 dev、staging 或 prod 之一。"
}
```

## 运行合法配置

先用默认值运行，所有校验应该通过：

```bash
terraform plan
```

## 触发校验失败

尝试传入不合法的值，观察错误信息：

```bash
terraform plan -var="instance_count=20"
```

你会看到类似输出：

```
Error: Invalid value for variable

  on main.tf line ...

instance_count 必须在 1 到 10 之间。
```

再试试其他校验：

```bash
terraform plan -var="image_id=invalid-id"
```

```bash
terraform plan -var="environment=test"
```

```bash
terraform plan -var="bucket_name=AB"
```

每次都会看到对应的 error_message。

## 多重校验

一个变量可以有多个 validation 块。看看 bucket_name 变量——它同时校验了长度范围和字符格式。所有 validation 都必须通过，任何一个失败都会报错。

试试触发格式校验：

```bash
terraform plan -var="bucket_name=INVALID_BUCKET"
```

## 跨变量引用校验（Terraform >= 1.9）

从 Terraform v1.9 开始，validation 中可以引用**其他变量**，不再局限于当前变量自身。看看代码中的 max_count 变量——它的 validation 引用了 var.min_count：

```hcl
variable "max_count" {
  type = number
  validation {
    condition     = var.max_count >= var.min_count
    error_message = "max_count 不能小于 min_count。"
  }
}
```

先用默认值运行（min_count=1, max_count=10），校验通过：

```bash
terraform plan -var="min_count=1" -var="max_count=10"
```

再试试让 max_count 小于 min_count，触发校验失败：

```bash
terraform plan -var="min_count=5" -var="max_count=2"
```

你会看到错误信息中同时显示了两个变量的值。

---

**注意：避免循环引用**

跨变量校验时，引用关系必须是**单向**的。如果 a 的 validation 引用 b，b 的 validation 又引用 a，就会形成循环依赖，Terraform 会直接报错。

经验法则：只在一侧（通常是"较大"的那个变量）放置跨变量 validation。
