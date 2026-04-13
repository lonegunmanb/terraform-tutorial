#!/bin/bash

echo "========================================="
echo "  正在为你准备 Checkov 实验环境..."
echo "  请稍候，预计需要 1-2 分钟"
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
echo "  - Checkov（Terraform 安全合规扫描工具）"
echo ""
echo "工作目录中有一个故意包含安全问题的 Terraform 项目"
echo "你将使用 Checkov 发现并修复这些问题"
echo ""
echo "进入工作目录开始实验：cd /root/workspace"
echo ""
