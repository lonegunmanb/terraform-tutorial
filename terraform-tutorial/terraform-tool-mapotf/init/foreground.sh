#!/bin/bash


echo "========================================="
echo "  正在为你准备 mapotf 实验环境..."
echo "  请稍候，预计需要 1-2 分钟"
echo "  （需要安装 Go 和 mapotf）"
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
echo "  - AWS CLI（含 awslocal 封装）"
echo "  - LocalStack（EC2 已启动）"
echo "  - mapotf（Terraform 元编程工具）"
echo "  - terraform-aws-modules/vpc/aws v5.16.0（已下载）"
echo ""
echo "实验场景：LocalStack 中有一个自动标签策略"
echo "会给所有 VPC 打上合规标签，导致 Terraform 检测到漂移"
echo ""
echo "进入工作目录开始实验：cd /root/workspace"
echo ""
