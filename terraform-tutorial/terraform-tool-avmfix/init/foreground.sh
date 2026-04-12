#!/bin/bash


echo "========================================="
echo "  正在为你准备 avmfix 实验环境..."
echo "  请稍候，预计需要 1-2 分钟"
echo "  （需要安装 Go 和 avmfix）"
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
echo "  - avmfix（Terraform 模块规范化工具）"
echo ""
echo "工作目录中有一个故意打乱格式的 Terraform 模块"
echo "你将使用 avmfix 自动修复它"
echo ""
echo "进入工作目录开始实验：cd /root/workspace"
echo ""
