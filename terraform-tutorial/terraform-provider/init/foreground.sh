#!/bin/bash


echo "========================================="
echo "  🔌 正在为你准备 Provider 实验环境..."
echo "  请稍候，预计需要 20-30 秒"
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
echo ""
echo "📁 工作目录结构："
echo "  /root/workspace/step1/          — 缺少 required_providers 的代码（故意出错）"
echo "  /root/workspace/step1/working/  — 正确声明的代码"
echo "  /root/workspace/step2/          — 练习题（需要你填写答案）"
echo ""
echo "👉 进入第一步：cd /root/workspace/step1"
echo ""
