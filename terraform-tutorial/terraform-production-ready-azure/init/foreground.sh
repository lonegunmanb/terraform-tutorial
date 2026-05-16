#!/bin/bash
echo "正在初始化实验环境，请稍候..."
echo ""

while [ ! -f /tmp/.setup-done ]; do
  sleep 3
  if docker ps 2>/dev/null | grep -q "miniblue"; then
    echo "  ✓ miniblue 正在运行"
    break
  fi
done

while [ ! -f /tmp/.setup-done ]; do
  sleep 3
done

echo ""
echo "环境已准备就绪！"
echo ""
echo "已安装："
echo "  - Terraform $(terraform version -json 2>/dev/null | python3 -c 'import sys,json; print(json.load(sys.stdin)["terraform_version"])' 2>/dev/null || terraform version | head -1)"
echo "  - Terragrunt $(terragrunt --version 2>&1 | head -1)"
echo "  - miniblue（VNet + VM + LB + Storage + CosmosDB + KeyVault + ...）"
echo "  - azlocal CLI（HTTP 4566，无需证书）"
echo "  - SSL_CERT_FILE 已配置（供 Terraform 走 HTTPS 4567）"
echo ""
echo "工作目录："
echo "  /root/workspace/  ← 单体大模块（本步实验）"
