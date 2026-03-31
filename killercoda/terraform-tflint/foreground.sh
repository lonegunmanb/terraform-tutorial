#!/bin/bash


echo "========================================="
echo "  🔍 正在为你准备 TFLint 实验环境..."
echo "  请稍候，预计需要 15-30 秒"
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
echo "  • TFLint"
echo "  • LocalStack (模拟 AWS)"
echo ""
echo "📌 当前代码中故意包含了一些问题，等你用 TFLint 发现它们。"
echo ""
echo "👉 输入 tflint --init 开始"
echo ""
