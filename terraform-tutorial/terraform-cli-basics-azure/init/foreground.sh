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
echo "  - azurerm provider 已通过 terraform init 下载完毕"
echo ""
echo "本课程聚焦 CLI 基础命令（fmt/console/get/graph/force-unlock），"
echo "不涉及实际 Azure 资源的 apply——所有命令均在本地完成。"
echo ""
echo "进入工作目录开始实验：cd /root/workspace"
echo ""
