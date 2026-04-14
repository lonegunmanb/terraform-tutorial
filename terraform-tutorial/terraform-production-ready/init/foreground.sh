#!/bin/bash
echo "正在初始化实验环境，请稍候..."
echo ""

while [ ! -f /tmp/.setup-done ]; do
  sleep 3
  if docker ps 2>/dev/null | grep -q "ministack\|localstack"; then
    echo "  ✓ MiniStack 正在运行"
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
echo "  - AWS CLI $(aws --version 2>&1 | cut -d' ' -f1)"
echo "  - MiniStack（VPC + EC2 + ELBv2 + S3 + SQS + SNS + DynamoDB + IAM + ...）"
echo ""
echo "工作目录："
echo "  /root/workspace/step1/  ← 单体大模块（本步实验）"
echo "  /root/workspace/step2/  ← 按架构层级拆分版（5 个模块）"
echo "  /root/workspace/step3/  ← 引入 terraform-aws-modules/vpc 版"
echo "  /root/workspace/step4/  ← 添加内置防护与版本固定版"
