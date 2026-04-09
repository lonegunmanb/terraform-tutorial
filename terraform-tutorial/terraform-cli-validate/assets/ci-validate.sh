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
