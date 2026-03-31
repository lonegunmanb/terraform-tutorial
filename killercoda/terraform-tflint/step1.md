# 第一步：初始化并运行 TFLint

进入工作目录：

```bash
cd /root/workspace
```

先看一下当前的 TFLint 配置：

```bash
cat .tflint.hcl
```

配置启用了三条规则：
- `terraform_naming_convention` — 命名规范检查
- `terraform_documented_variables` — 变量必须有 description
- `terraform_unused_declarations` — 未使用的声明检查

初始化 TFLint（下载规则插件）：

```bash
tflint --init
```

运行检查：

```bash
tflint
```

你应该看到多条告警和错误。仔细阅读每一条输出，记下问题所在的行号和原因。
