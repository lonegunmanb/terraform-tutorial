#!/bin/bash

echo "========================================="
echo "  📝 正在为你准备重载文件实验环境..."
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
echo "  • LocalStack（模拟 S3、SQS，用于第二步习题）"
echo ""
echo "📁 工作目录结构："
echo "  /root/workspace/step1/  — 重载文件基础：VPC + NAT Gateway 基础设施"
echo "  /root/workspace/step2/  — 小测验：编写重载文件"
echo ""
echo "👉 进入第一步：cd /root/workspace/step1"
echo ""
