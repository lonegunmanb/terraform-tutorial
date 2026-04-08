#!/bin/bash


echo "========================================="
echo "  正在为你准备 Terraform 实验环境..."
echo "  请稍候，预计需要 20-40 秒"
echo "========================================="

# Wait for background setup to finish
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
echo "  - LocalStack（S3 服务已启动）"
echo ""
echo "工作目录说明："
echo "  /root/workspace/          主工作目录（步骤 1 和 2 使用）"
echo "  /root/workspace/backend-demo/  backend 迁移演示目录（步骤 3 使用）"
echo ""
echo "进入工作目录开始实验：cd /root/workspace"
echo ""
