#!/bin/bash

echo "========================================="
echo "  正在为你准备 Conftest 实验环境..."
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
echo "  - Conftest（基于 OPA 的策略测试工具）"
echo "  - LocalStack（本地 AWS 模拟环境）"
echo ""
echo "工作目录中有一个 Terraform 项目和预写好的 Rego 策略"
echo "你将使用 Conftest 检查不合规配置并修复"
echo ""
echo "进入工作目录开始实验：cd /root/workspace"
echo ""
