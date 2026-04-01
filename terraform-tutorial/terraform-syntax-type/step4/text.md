# 第四步：练习与测试

现在轮到你来写代码了！完成四道练习题，然后用 `terraform test` 验证答案。

## 查看练习文件

```bash
cd /root/workspace/step4
cat exercises.tf
```

文件中有四道练习，每道都标有 >>> 在此处写入你的代码 <<< 的提示。

## 练习说明

### 练习 1：定义 list(number) 变量

定义一个 `variable "scores"` 块：
- 类型为 `list(number)`
- 默认值为 `[90, 85, 72, 95]`

### 练习 2：定义 map(string) 变量

定义一个 `variable "labels"` 块：
- 类型为 `map(string)`
- 默认值包含三个键值对：`app = "web"`、`env = "prod"`、`team = "backend"`

### 练习 3：定义带 optional 属性的 object 变量

定义一个 `variable "app_config"` 块：
- 类型为 `object`，包含：
  - `name = string`（必填）
  - `replicas = optional(number, 1)`（可选，默认 1）
  - `debug = optional(bool, false)`（可选，默认 false）
- 默认值只设置 `name = "my-app"`

### 练习 4：使用集合函数和类型操作

定义一个 `locals` 块，包含：
- `highest_score = max(var.scores...)`（用 `...` 展开 list 传入 `max()` 函数）
- `app_label`：用字符串插值拼接 `var.labels["app"]` 和 `var.labels["env"]`，格式为 `"<app>-<env>"`
- `replica_count = var.app_config.replicas`（读取 optional 属性，验证默认值生效）

## 编辑文件

用编辑器修改 `exercises.tf`，完成四道练习。

> ⚠️ 不要修改 `outputs.tf` 和 `tests/` 目录中的文件，它们用于自动验证你的答案。

## 验证答案

完成编辑后，运行测试：

```bash
terraform test
```

如果所有测试通过，你会看到类似输出：

```
tests/exercises.tftest.hcl... pass
  run "check_list_variable"... pass
  run "check_map_variable"... pass
  run "check_object_optional"... pass
  run "check_expressions"... pass

Success! 4 passed, 0 failed.
```

如果有测试失败，错误信息会告诉你哪道练习有问题，修改后重新运行 `terraform test` 即可。

✅ 所有测试通过后，你就完成了类型系统的学习！
