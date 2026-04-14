# 第四步：内置防护与版本固定

## 查看添加了防护的代码

```bash
cd /root/workspace/step4
```

这一步我们在三个模块里各加了一种防护，在根模块里加了版本约束。

## 1. validation 块：在变量层面拦截非法输入

```bash
cat modules/queue/variables.tf
```

`message_retention_seconds` 变量现在有了 `validation` 块。试试传一个非法值：

```bash
terraform plan -var="message_retention_seconds=30"
```

你会立刻看到错误，不需要等到 apply 阶段，也不需要 AWS API 调用：

```
│ Error: Invalid value for variable
│
│   Only free tier is allowed: ...
│
│ This was checked by the validation rule at ...
```

再试一个有效值：

```bash
terraform plan -var="message_retention_seconds=3600"
```

## 2. precondition 块：在 apply 之前检查假设条件

```bash
cat modules/storage/main.tf
```

注意 `aws_s3_bucket` resource 里的 `lifecycle { precondition { ... } }`。

这个 precondition 检查 bucket 名称长度是否符合 AWS 规范（3–63 字符）。与 `validation` 不同，precondition 可以引用表达式和函数，适合更复杂的约束。

试试触发它：

```bash
terraform plan -var="app_name=x"
```

观察报错发生在 plan 阶段，在任何资源变更之前。

## 3. postcondition 块：在 apply 之后验证保证条件

```bash
cat modules/database/main.tf
```

`aws_dynamodb_table` resource 里有一个 `lifecycle { postcondition { ... } }`。

postcondition 用 `self` 引用当前资源的实际属性——verify that what was created matches what was intended。这是模块对外的**行为保证**：调用方相信"只要这个模块 apply 成功，表就一定是按需计费模式"。

## 4. 版本固定：让部署可重现

```bash
cat main.tf | head -20
```

注意 `required_version` 和 `required_providers` 的写法，以及 `.terraform.lock.hcl` 的存在：

```bash
terraform init
cat .terraform.lock.hcl
```

这个文件记录了实际下载的 provider 版本和哈希校验值。**把这个文件提交到版本控制**，同一份代码在任何机器上的 `terraform init` 都会得到完全相同的 provider 版本。

## 完整部署

```bash
terraform apply -auto-approve
```

## 模块安全测试

验证防护机制在边界情况下的行为：

```bash
# 测试：消息保留时长超出最大值（应该立刻报错）
terraform plan -var="message_retention_seconds=9999999"
```

```bash
# 测试：应用名称太短（应该在 plan 阶段报错）
terraform plan -var="app_name=ab"
```

```bash
# 正常部署
terraform apply -auto-approve
```

## 三层防护对比

```bash
# 查看三种防护的位置
grep -n "validation\|precondition\|postcondition" \
  modules/queue/variables.tf \
  modules/storage/main.tf \
  modules/database/main.tf
```

| 工具 | 触发时机 | 可引用的内容 | 适用场景 |
|------|---------|------------|---------|
| `validation` | plan 之前 | 仅当前变量 | 变量基础合法性 |
| `precondition` | apply 之前 | 数据源、表达式 | 跨变量/资源的前置断言 |
| `postcondition` | apply 之后 | `self.*`（当前资源） | 模块行为的对外保证 |

## 最终状态

```bash
terraform state list
terraform output
```

与第一步的单体相比，现在这套系统：
- 代码按职责拆分在独立模块中，可单独测试和复用
- 存储模块依赖经过验证的社区实现
- 关键约束内嵌在模块里，传入非法配置时立即报错
- provider 和模块版本有明确约束，部署可重现

恭喜完成了本实验的所有步骤！
