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
  "format_version": "1.0",
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

工作目录中已预置了一个 CI 验证脚本 ci-validate.sh，查看其内容：

```
cat ci-validate.sh
```

脚本流程：init → fmt -check → validate -json → 解析 valid 字段判断成功/失败。

先用正确配置测试：

```
bash ci-validate.sh
```

全部通过。再制造一个错误测试：

```
sed -i 's/bucket = "${var.app_name}/buckeet = "${var.app_name}/' main.tf
bash ci-validate.sh
```

脚本检测到错误，打印 JSON 详情并以非零退出码退出——在 CI 中会中断流水线。

恢复配置：

```
sed -i 's/buckeet = "${var.app_name}/bucket = "${var.app_name}/' main.tf
terraform validate
```

确认 Success 后进入完成页。
