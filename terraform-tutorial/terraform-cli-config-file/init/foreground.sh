#!/bin/bash


echo "========================================="
echo "  正在为你准备实验环境..."
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
echo "注意：terraform init 尚未执行，你将在实验中"
echo "通过不同配置方式自行初始化。"
echo ""
echo "进入工作目录开始实验：cd /root/workspace"
echo ""
