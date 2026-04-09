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
echo "  - LocalStack（S3 已启动）"
echo ""
echo "terraform init 已完成（providers 已下载）"
echo "尚未创建任何资源"
echo ""
echo "进入工作目录开始实验：cd /root/workspace"
echo ""
