#!/bin/bash
# show-lock.sh — 演示 Terraform 状态锁定
# 后台运行 terraform apply，等待锁出现后展示锁信息

set -e
cd /root/workspace/step2

echo "========================================"
echo "  开始演示状态锁定"
echo "========================================"
echo ""

# 1. 后台启动 terraform apply（time_sleep 会阻塞 30 秒）
echo ">>> 后台启动 terraform apply ..."
terraform apply -auto-approve > /tmp/apply.log 2>&1 &
APPLY_PID=$!
echo "    apply PID: $APPLY_PID"
echo ""

# 2. 轮询等待锁出现
echo ">>> 等待 Terraform 获取锁 ..."
for i in $(seq 1 15); do
  LOCK_COUNT=$(awslocal dynamodb scan --table-name terraform-locks --query 'Count' --output text 2>/dev/null || echo "0")
  if [ "$LOCK_COUNT" -gt 0 ] 2>/dev/null; then
    break
  fi
  sleep 2
done

# 3. 展示锁信息
echo ""
echo "========================================"
echo "  DynamoDB 锁表内容"
echo "========================================"
awslocal dynamodb scan --table-name terraform-locks --output json 2>/dev/null | python3 -m json.tool
echo ""

# 4. 解析并展示 Info 字段
echo "========================================"
echo "  锁的详细信息"
echo "========================================"
awslocal dynamodb scan --table-name terraform-locks --output json 2>/dev/null \
  | python3 -c "
import json, sys
data = json.load(sys.stdin)
for item in data.get('Items', []):
    lock_id = item.get('LockID', {}).get('S', '未知')
    info_raw = item.get('Info', {}).get('S', '{}')
    info = json.loads(info_raw)
    print(f'  LockID:    {lock_id}')
    print(f'  Operation: {info.get(\"Operation\", \"未知\")}')
    print(f'  Who:       {info.get(\"Who\", \"未知\")}')
    print(f'  Created:   {info.get(\"Created\", \"未知\")}')
" 2>/dev/null || echo "  (无法解析锁信息)"
echo ""

# 5. 尝试并发操作，展示锁冲突
echo "========================================"
echo "  尝试并发执行 terraform plan ..."
echo "========================================"
echo ""
terraform plan 2>&1 || true
echo ""

# 6. 等待后台 apply 完成
echo "========================================"
echo "  等待后台 apply 完成 ..."
echo "========================================"
wait $APPLY_PID
EXIT_CODE=$?
echo "  apply 完成，退出码: $EXIT_CODE"
echo ""

# 7. 确认锁已释放
echo "========================================"
echo "  确认锁已释放"
echo "========================================"
LOCK_COUNT=$(awslocal dynamodb scan --table-name terraform-locks --query 'Count' --output text 2>/dev/null)
echo "  锁表记录数: $LOCK_COUNT"
if [ "$LOCK_COUNT" = "0" ]; then
  echo "  锁已自动释放！"
else
  echo "  警告: 锁未释放，请检查 /tmp/apply.log"
fi
echo ""
echo "========================================"
echo "  演示结束"
echo "========================================"
