#!/bin/bash

echo "========================================="
echo "  📝 正在为你准备数据源实验环境..."
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
echo "  • LocalStack（模拟 S3、SQS、STS）"
echo ""
echo "📁 工作目录结构："
echo "  /root/workspace/step1/  — 数据源基础：查询环境信息"
echo "  /root/workspace/step2/  — data + resource 协作"
echo "  /root/workspace/step3/  — 小测验：terraform test"
echo ""
echo "👉 进入第一步：cd /root/workspace/step1"
echo ""
