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
echo "  - miniblue（Azure 本地模拟器，端口 4566 / 4567）"
echo "  - azlocal CLI（类似 awslocal，HTTP 4566，无需证书）"
echo "  - 自签名证书已通过 SSL_CERT_FILE 信任（供 Terraform 走 HTTPS）"
echo ""
echo "工作目录：/root/workspace（azurerm provider 已通过 terraform init 下载）"
echo "已通过 miniblue ARM API 预创建了若干 Resource Group，模拟'先有基础设施'的场景。"
