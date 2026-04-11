#!/bin/bash
# auto-tag-vpc.sh — 模拟 AWS 合规策略自动给 VPC 打标签
# 每 5 秒检查一次，给所有没有 compliance-team 标签的 VPC 打上标签

export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

while true; do
  sleep 5
  # 列出所有 VPC
  VPC_IDS=$(aws --endpoint-url=http://localhost:4566 ec2 describe-vpcs \
    --query 'Vpcs[*].VpcId' --output text 2>/dev/null)

  for VPC_ID in $VPC_IDS; do
    # 检查是否已经有 compliance-team 标签
    HAS_TAG=$(aws --endpoint-url=http://localhost:4566 ec2 describe-tags \
      --filters "Name=resource-id,Values=${VPC_ID}" "Name=key,Values=compliance-team" \
      --query 'Tags[0].Value' --output text 2>/dev/null)

    if [ "$HAS_TAG" = "None" ] || [ -z "$HAS_TAG" ]; then
      aws --endpoint-url=http://localhost:4566 ec2 create-tags \
        --resources "$VPC_ID" \
        --tags Key=compliance-team,Value=security Key=auto-tagged-at,Value="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        2>/dev/null
    fi
  done
done
