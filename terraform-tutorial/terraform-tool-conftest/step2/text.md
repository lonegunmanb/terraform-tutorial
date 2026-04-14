# 高级策略与例外管理

## 编写 warn 规则

除了 deny（失败），Rego 还支持 warn（警告）。警告不会导致 Conftest 返回非零退出码，适合用于建议性的最佳实践。

创建一条警告规则，建议为 S3 桶开启访问日志：

```
cat > policy/s3_logging.rego <<'EOF'
package main

import rego.v1

warn contains msg if {
  resource := input.resource_changes[_]
  resource.type == "aws_s3_bucket"
  actions := resource.change.actions
  actions[_] == "create"

  bucket_address := resource.address
  not has_logging(bucket_address)

  msg := sprintf("建议为 S3 桶 '%s' 配置访问日志（aws_s3_bucket_logging）", [bucket_address])
}

has_logging(bucket_address) if {
  res := input.configuration.root_module.resources[_]
  res.type == "aws_s3_bucket_logging"
  some expr in res.expressions.bucket.references
  contains(expr, bucket_address)
}
EOF
```

运行检查看看效果：

```
conftest test -o table tfplan.json
```

你会看到新的 WARN 行——建议为桶配置访问日志。但测试结果仍然是通过的，WARN 不影响退出码：

```
echo "退出码: $?"
```

## 使用命名空间组织策略

当策略数量增多时，可以使用 Rego 的 package 进行分组。目前所有策略都在 package main 中。我们来创建一个独立命名空间的策略：

```
cat > policy/s3_naming.rego <<'EOF'
package s3.naming

import rego.v1

deny contains msg if {
  resource := input.resource_changes[_]
  resource.type == "aws_s3_bucket"
  actions := resource.change.actions
  actions[_] == "create"

  bucket_name := resource.change.after.bucket
  not startswith(bucket_name, "acme-")

  msg := sprintf("S3 桶 '%s' 的名称 '%s' 必须以 'acme-' 前缀开头", [resource.address, bucket_name])
}
EOF
```

默认情况下 Conftest 只运行 package main 中的策略：

```
conftest test tfplan.json
```

用 --all-namespaces 参数运行所有命名空间：

```
conftest test --all-namespaces -o table tfplan.json
```

你会看到 s3.naming 命名空间下的 FAIL——两个桶的名称都不以 acme- 开头。

也可以用 --namespace 只运行特定命名空间：

```
conftest test --namespace s3.naming -o table tfplan.json
```

## 创建策略例外

在实际项目中，某些策略可能需要对特定场景做例外。Conftest 支持通过 exception 规则跳过特定检查。

命名策略不适用于本实验的测试桶，我们为它创建例外。创建一个例外文件：

```
cat > policy/exceptions.rego <<'EOF'
package s3.naming

import rego.v1

exception contains rules if {
  rules = ["deny"]
}
EOF
```

这个例外文件和策略在同一个 package（s3.naming）下，它声明跳过该命名空间中所有 deny 规则。

运行检查确认例外生效：

```
conftest test --all-namespaces -o table tfplan.json
```

s3.naming 命名空间下的失败消失了，策略被标记为例外跳过。

## 使用 JSON 输出

在 CI 管道中，JSON 格式更方便程序化处理：

```
conftest test -o json tfplan.json 2>/dev/null | head -30
```

JSON 输出包含每条检查的详细结果，可以被自动化工具解析。

## 使用 --no-fail 模式

类似 checkov 的 --soft-fail，Conftest 提供 --no-fail 参数：

```
conftest test --all-namespaces tfplan.json --no-fail
echo "退出码: $?"
```

即使有 FAIL 也返回退出码 0。适合在逐步引入策略时使用。

## 清理并验证最终状态

删除命名规范策略和例外（它们只是演示用的），保留核心安全策略：

```
rm -f policy/s3_naming.rego policy/exceptions.rego
```

最终确认所有核心策略通过：

```
conftest test -o table tfplan.json
```

## 总结

通过本步骤你学到了：

| 功能 | 说明 |
|------|------|
| warn 规则 | 建议性检查，不影响退出码 |
| 命名空间 | 用 package 组织策略，--all-namespaces 运行全部 |
| 例外机制 | exception 规则跳过特定检查 |
| JSON 输出 | -o json 格式化输出 |
| --no-fail | 即使有失败也返回退出码 0 |
