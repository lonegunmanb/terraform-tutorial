#!/bin/bash


echo "========================================="
echo "  📝 正在为你准备表达式实验环境..."
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
echo ""
echo "📁 工作目录结构："
echo "  /root/workspace/step1/  — 运算符与条件表达式示例"
echo "  /root/workspace/step2/  — 字符串模板与函数调用示例"
echo "  /root/workspace/step3/  — for 表达式与 splat 示例"
echo "  /root/workspace/step4/  — 练习题（需要你编写代码）"
echo ""
echo "👉 进入第一步：cd /root/workspace/step1"
echo ""
