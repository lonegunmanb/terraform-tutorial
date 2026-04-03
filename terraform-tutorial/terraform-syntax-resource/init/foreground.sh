#!/bin/bash

echo "========================================="
echo "  📝 正在为你准备资源实验环境..."
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
echo "  • LocalStack（模拟 S3、SQS、DynamoDB、SNS）"
echo ""
echo "📁 工作目录结构："
echo "  /root/workspace/step1/  — 资源基础：S3 存储桶与对象"
echo "  /root/workspace/step2/  — count 与 for_each：批量创建"
echo "  /root/workspace/step3/  — lifecycle、dynamic 与 provisioner"
echo ""
echo "👉 进入第一步：cd /root/workspace/step1"
echo ""
