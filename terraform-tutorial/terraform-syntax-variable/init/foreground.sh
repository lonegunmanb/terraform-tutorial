#!/bin/bash

echo "========================================="
echo "  📝 正在为你准备输入变量实验环境..."
echo "  请稍候，预计需要 20-30 秒"
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
echo "  • LocalStack（模拟 AWS EC2，用于练习题）"
echo ""
echo "📁 工作目录结构："
echo "  /root/workspace/step1/  — 变量基础（type、default、description）"
echo "  /root/workspace/step2/  — 断言校验（validation）"
echo "  /root/workspace/step3/  — 敏感值与临时变量（sensitive、ephemeral、nullable）"
echo "  /root/workspace/step3/  — 赋值方式与优先级（和第三步共用目录）"
echo "  /root/workspace/step5/  — 练习题（用变量创建 EC2 实例）"
echo ""
echo "👉 进入第一步：cd /root/workspace/step1"
echo ""
