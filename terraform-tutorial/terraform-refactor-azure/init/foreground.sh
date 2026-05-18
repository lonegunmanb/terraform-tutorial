#!/bin/bash

echo "========================================="
echo "  📝 正在为你准备代码重构实验环境（Azure 版）..."
echo "  请稍候，预计需要 60-90 秒"
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
echo "  • miniblue（Azure 本地模拟器）"
echo "  • azlocal（miniblue 自带 CLI，行为类似 az）"
echo ""
echo "📁 工作目录结构："
echo "  /root/workspace/step1/      — import：纳入已有资源"
echo "  /root/workspace/step2/      — removed：移除托管资源"
echo "  /root/workspace/step3/      — moved：重命名资源"
echo "  /root/workspace/step4/      — moved：提取到模块"
echo ""
echo "🔧 已预创建的共享 Resource Group：refactor-rg（eastus）"
echo ""
echo "👉 进入第一步：cd /root/workspace/step1"
echo ""
