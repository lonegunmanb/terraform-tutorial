#!/bin/bash
# show-lock.sh — 演示 azurerm 后端的 blob lease 状态锁定
# 后台启动一个会阻塞 30 秒的 terraform apply，期间另一个 terraform plan 会因租约冲突而失败

cd /root/workspace

echo "========================================"
echo "  开始演示 azurerm 后端状态锁定"
echo "  （锁机制：blob lease，作用在状态 blob 本身）"
echo "========================================"
echo ""

# 1. 后台启动 terraform apply（time_sleep 阻塞 30 秒）
echo ">>> 后台启动 terraform apply ..."
terraform apply -auto-approve > /tmp/apply.log 2>&1 &
APPLY_PID=$!
echo "    apply PID: $APPLY_PID"
echo ""

# 2. 等待 apply 真正启动并获取租约
echo ">>> 等待 Terraform 获取 blob lease ..."
sleep 5
echo ""

# 3. 尝试并发 plan，应被状态锁拒绝
echo "========================================"
echo "  并发执行 terraform plan（预期报锁冲突）"
echo "========================================"
echo ""
terraform plan 2>&1 || true
echo ""

# 4. 等待后台 apply 完成
echo "========================================"
echo "  等待后台 apply 完成 ..."
echo "========================================"
wait $APPLY_PID || true
EXIT_CODE=$?
echo "  apply 退出码: $EXIT_CODE"
echo ""

# 5. 再次 plan，应能正常执行（租约已释放）
echo "========================================"
echo "  apply 完成后再次 plan（租约应已释放）"
echo "========================================"
terraform plan 2>&1 | tail -20 || true
echo ""

echo "========================================"
echo "  演示结束"
echo "  完整 apply 日志：cat /tmp/apply.log"
echo "========================================"
