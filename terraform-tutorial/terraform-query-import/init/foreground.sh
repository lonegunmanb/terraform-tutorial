#!/bin/bash


echo "========================================="
echo "  正在为你准备批量导入实验环境..."
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
echo "  - AWS CLI（含 awslocal 封装）"
echo "  - LocalStack（S3 + DynamoDB 已启动）"
echo ""
echo "LocalStack 中已预先创建了若干 S3 桶和 DynamoDB 表"
echo "（模拟手动或由其他工具创建的已有资源）"
echo "你的任务是将它们导入 Terraform 管理"
echo ""
echo "进入工作目录开始实验：cd /root/workspace"
echo ""
