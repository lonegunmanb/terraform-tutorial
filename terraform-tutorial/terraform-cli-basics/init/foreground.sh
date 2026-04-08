#!/bin/bash


echo "========================================="
echo "  🏗️  正在为你准备 Terraform 实验环境..."
echo "  请稍候，预计需要 15-30 秒"
echo "========================================="

# Wait for background setup to finish
while [ ! -f /tmp/.setup-done ]; do
  sleep 2
  echo "⏳ 环境初始化中..."
done

echo ""
echo "✅ 环境准备就绪！"
echo ""
echo "已为你预装："
echo "  • Terraform CLI"
echo "  • null provider（已预初始化）"
echo ""
echo "👉 进入工作目录开始实验：cd /root/workspace"
echo ""
