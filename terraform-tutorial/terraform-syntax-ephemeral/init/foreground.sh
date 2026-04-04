#!/bin/bash

echo "========================================="
echo "  📝 正在为你准备临时资源实验环境..."
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
echo "  • Terraform CLI (>= 1.10，支持 ephemeral)"
echo "  • LocalStack（模拟 Secrets Manager）"
echo "  • AWS CLI（awslocal 验证 Secret 内容）"
echo ""
echo "📁 工作目录结构："
echo "  /root/workspace/step1/  — ephemeral vs resource 对比"
echo "  /root/workspace/step2/  — ephemeral + Secrets Manager"
echo "  /root/workspace/step3/  — 小测验"
echo ""
echo "👉 进入第一步：cd /root/workspace/step1"
echo ""
