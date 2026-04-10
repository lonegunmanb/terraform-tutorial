#!/bin/bash


echo "========================================="
echo "  正在为你准备 Terraform 实验环境..."
echo "  请稍候，预计需要 30-60 秒"
echo "========================================="

while [ ! -f /tmp/.setup-done ]; do
  sleep 2
  echo "环境初始化中..."
done

echo ""
echo "环境准备就绪！"
echo ""
echo "已为你预装："
echo "  - Terraform CLI"
echo "  - AWS CLI（含 awslocal 封装）"
echo "  - LocalStack（S3 + DynamoDB 已启动）"
echo ""
echo "工作目录：/root/workspace"
echo "已通过 awslocal 预创建了若干 S3 桶，模拟'先有基础设施'的场景。"
