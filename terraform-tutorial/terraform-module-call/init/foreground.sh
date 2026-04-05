#!/bin/bash

echo "========================================="
echo "  📝 正在为你准备模块调用实验环境..."
echo "  请稍候，预计需要 60-90 秒"
echo "========================================="

while [ ! -f /tmp/.setup-done ]; do
  sleep 2
  echo "⏳ 环境初始化中..."
done

echo ""
echo "✅ 环境准备就绪！"
echo ""
echo "已为你预装："
echo "  • Terraform CLI"
echo "  • LocalStack（模拟 S3）"
echo ""
echo "📁 工作目录结构："
echo "  /root/workspace/modules/    — 共享模块"
echo "  /root/workspace/step1/      — 模块来源与版本约束"
echo "  /root/workspace/step2/      — 传参与输出引用"
echo "  /root/workspace/step3/      — count 和 for_each"
echo "  /root/workspace/step4/      — 测验"
echo ""
echo "👉 进入第一步：cd /root/workspace/step1"
echo ""
