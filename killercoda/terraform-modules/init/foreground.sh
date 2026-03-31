#!/bin/bash


echo "========================================="
echo "  📦 正在为你准备模块化实验环境..."
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
echo "  • LocalStack (模拟 AWS: S3)"
echo ""
echo "📌 工作目录中已有一个 S3 模块和根模块。"
echo ""
echo "👉 输入 tree 查看项目结构"
echo ""
