# 第三步：-json 机器可读输出与 CI 集成

## 正确配置的 JSON 输出

使用 -json 选项获取机器可读的验证结果：

```
cd /root/workspace
terraform validate -json
```

输出是一个 JSON 对象：

```
{
  "valid": true,
  "error_count": 0,
  "warning_count": 0,
  "diagnostics": []
}
```

valid 为 true 表示配置通过验证，diagnostics 数组为空。

## 有错误时的 JSON 输出

制造一个错误，观察 JSON 格式的错误报告：

```
sed -i 's/bucket = "${var.app_name}/buckeet = "${var.app_name}/' main.tf
terraform validate -json
```

输出中 valid 变为 false，diagnostics 数组包含详细的错误信息：

```
terraform validate -json | python3 -m json.tool
```

用 python3 格式化后可以清晰看到每个字段：

- severity：错误级别（error 或 warning）
- summary：错误摘要（如 Unsupported argument）
- detail：修复建议（如 Did you mean "bucket"?）
- range：错误位置（文件名、行号、列号）

恢复配置：

```
sed -i 's/buckeet = "${var.app_name}/bucket = "${var.app_name}/' main.tf
```

## CI 集成脚本

在 CI 中，可以结合 -json 和退出码编写验证门禁脚本：

```
cat > /tmp/ci-validate.sh <<'SCRIPT'
#!/bin/bash
set -euo pipefail

echo "=== Step 1: terraform init ==="
terraform init -backend=false -input=false > /dev/null 2>&1

echo "=== Step 2: terraform fmt -check ==="
if ! terraform fmt -check -recursive > /dev/null 2>&1; then
  echo "FAIL: 代码格式不符合规范，请运行 terraform fmt"
  exit 1
fi
echo "PASS: 格式检查通过"

echo "=== Step 3: terraform validate ==="
RESULT=$(terraform validate -json)
VALID=$(echo "$RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['valid'])")
ERRORS=$(echo "$RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['error_count'])")
WARNINGS=$(echo "$RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['warning_count'])")

if [ "$VALID" = "True" ]; then
  echo "PASS: 验证通过 (warnings: $WARNINGS)"
else
  echo "FAIL: 验证失败 (errors: $ERRORS, warnings: $WARNINGS)"
  echo "$RESULT" | python3 -m json.tool
  exit 1
fi
SCRIPT
chmod +x /tmp/ci-validate.sh
```

先用正确配置测试：

```
bash /tmp/ci-validate.sh
```

全部通过。再制造一个错误测试：

```
sed -i 's/bucket = "${var.app_name}/buckeet = "${var.app_name}/' main.tf
bash /tmp/ci-validate.sh
```

脚本检测到错误，打印 JSON 详情并以非零退出码退出——在 CI 中会中断流水线。

恢复配置：

```
sed -i 's/buckeet = "${var.app_name}/bucket = "${var.app_name}/' main.tf
terraform validate
```

确认 Success 后进入完成页。
