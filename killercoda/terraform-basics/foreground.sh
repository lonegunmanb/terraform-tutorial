#!/bin/bash
set -e

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
echo "  • TFLint"
echo "  • LocalStack (模拟 AWS: S3, IAM, DynamoDB)"
echo ""
echo "👉 输入 terraform init 开始实验"
echo ""
