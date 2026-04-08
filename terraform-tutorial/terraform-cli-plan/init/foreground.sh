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
echo "已预先执行 terraform apply，三个资源已存在："
echo "  - S3: myapp-dev-app-lab"
echo "  - S3: myapp-dev-logs-lab"
echo "  - DynamoDB: myapp-dev-sessions"
echo ""
echo "进入工作目录开始实验：cd /root/workspace"
echo ""
