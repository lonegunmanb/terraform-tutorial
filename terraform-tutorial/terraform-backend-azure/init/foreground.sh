#!/bin/bash

echo "========================================="
echo "  正在为你准备 Backend 实验环境（Azure / miniblue）..."
echo "  请稍候，预计需要 30-60 秒"
echo "========================================="

while [ ! -f /tmp/.setup-done ]; do
  sleep 2
  echo "  环境初始化中..."
done

echo ""
echo "  环境准备就绪！"
echo ""
echo "已为你预装："
echo "  - Terraform CLI"
echo "  - miniblue（Azure 本地模拟器，端口 4566 / 4567）"
echo "  - azlocal CLI（类似 awslocal，HTTP 4566，无需证书）"
echo "  - 自签名证书已通过 SSL_CERT_FILE 信任"
echo ""
echo "  进入工作目录开始实验：cd /root/workspace"
echo ""
