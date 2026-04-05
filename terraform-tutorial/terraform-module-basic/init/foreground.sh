#!/bin/bash

echo "========================================="
echo "  📝 正在为你准备模块实验环境..."
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
echo "  • LocalStack（模拟 S3）"
echo ""
echo "📁 工作目录结构："
echo "  /root/workspace/step1/  — 根模块与标准结构"
echo "  /root/workspace/step2/  — 创建并调用子模块"
echo "  /root/workspace/step3/  — 测验：自己编写模块"
echo ""
echo "👉 进入第一步：cd /root/workspace/step1"
echo ""
