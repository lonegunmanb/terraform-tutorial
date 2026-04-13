# 基础检查：发现代码中的问题

## 进入工作目录

```
cd /root/workspace
```

## 查看当前代码

先看看我们的 Terraform 代码：

```
cat main.tf
```

这段代码包含了多种常见问题，但 terraform validate 能发现吗？

## 用 terraform validate 检查

先初始化，然后验证：

```
terraform init
terraform validate
```

你会看到 "Success! The configuration is valid." — terraform validate 认为代码没有问题。

但实际上，代码中隐藏着多个不规范的写法。接下来用 tflint 来发现它们。

## 用 tflint 进行首次扫描

直接运行 tflint（无需配置文件也能使用内置规则）：

```
tflint
```

tflint 会输出一系列警告和错误。仔细阅读每一条输出，你会发现 terraform validate 完全没有报告的问题：

1. **废弃的插值语法** — "${var.bucket_name}" 应该直接写成 var.bucket_name。在早期版本的 Terraform 中，所有变量引用都需要包裹在 "${}" 中，但从 Terraform 0.12 开始，简单变量引用不再需要这种写法。tflint 的 terraform_deprecated_interpolation 规则会检测到这个问题。

2. **其他问题** — 根据 tflint 的默认规则集，可能还会检测到其他问题。

注意 tflint 输出中每条消息的格式：

- Warning / Error — 严重级别
- 规则名称（如 terraform_deprecated_interpolation）
- 问题文件和行号

## 理解 tflint 的优势

terraform validate 通过了，但 tflint 发现了问题。这就是 tflint 的价值——它不仅检查语法是否正确，还检查代码是否**规范**。

下一步，我们将通过配置文件启用更多规则来发现更多潜在问题。
