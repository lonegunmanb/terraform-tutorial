#!/bin/bash


echo "========================================="
echo "  💾 正在为你准备状态管理实验环境..."
echo "  请稍候，预计需要 30-60 秒"
echo "========================================="

while [ ! -f /tmp/.setup-done ]; do
  sleep 2
  echo "⏳ 环境初始化中..."
done

echo ""
echo "✅ 环境准备就绪！"
echo ""
echo "已为你预装："
echo "  • Terraform CLI"
echo "  • LocalStack (模拟 AWS: S3, IAM, DynamoDB)"
echo ""
echo "📌 已自动执行 terraform apply，当前有已管理的资源。"
echo ""
echo "👉 输入 terraform state list 开始探索状态"
echo ""
