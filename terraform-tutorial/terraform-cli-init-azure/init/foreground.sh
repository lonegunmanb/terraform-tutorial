#!/bin/bash


echo "========================================="
echo "  正在为你准备 Terraform + Azure(miniblue) 实验环境..."
echo "  请稍候，预计需要 30-60 秒"
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
echo "  - miniblue（Azure 本地模拟器，端口 4566 / 4567）"
echo "  - azlocal CLI（类似 awslocal，HTTP 4566，无需证书）"
echo "  - 自签名证书已通过 SSL_CERT_FILE 信任（供 Terraform 走 HTTPS）"
echo ""
echo "工作目录说明："
echo "  /root/workspace/               主工作目录（步骤 1 和 2 使用）"
echo "  /root/workspace/backend-demo/  backend 迁移演示目录（步骤 3 使用，已 apply 本地 state）"
echo ""
echo "步骤 3 需要的 Storage Account 已预先创建："
echo "  Resource Group:  tfstate-rg"
echo "  Storage Account: tfstateinit"
echo "  Container:       tfstate"
echo ""
echo "进入工作目录开始实验：cd /root/workspace"
echo ""
