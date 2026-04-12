#!/bin/bash


echo "========================================="
echo "  正在为你准备 terraform-docs 实验环境..."
echo "  请稍候，预计需要 30 秒"
echo "========================================="

while [ ! -f /tmp/.setup-done ]; do
  sleep 2
  echo "环境初始化中..."
done

echo ""
echo "环境准备就绪！"
echo ""
echo "已为你预装："
echo "  - terraform-docs CLI"
echo ""
echo "工作目录中有一个 S3 静态网站模块"
echo "你将使用 terraform-docs 为它自动生成文档"
echo ""
echo "进入工作目录开始实验：cd /root/workspace"
echo ""
