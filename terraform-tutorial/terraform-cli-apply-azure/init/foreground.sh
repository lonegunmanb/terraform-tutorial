#!/bin/bash


echo "========================================="
echo "  正在为你准备 Terraform + Azure(miniblue) 实验环境..."
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
echo "  - miniblue（Azure 本地模拟器，镜像版本 0.7.0，端口 4566 / 4567）"
echo "  - 自签名证书已通过 SSL_CERT_FILE 信任"
echo ""
echo "terraform init 已完成（azurerm provider 已下载）"
echo "尚未创建任何资源——你将在第一步执行首次 apply"
echo ""
echo "进入工作目录开始实验：cd /root/workspace"
echo ""
