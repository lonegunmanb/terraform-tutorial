#!/bin/bash
set +x
echo "正在准备 Azure / miniblue 生产就绪代码实验环境..."
while [ ! -f /tmp/.setup-done ]; do
  echo "Terraform、Terragrunt 与 miniblue 正在初始化，请稍候..."
  sleep 5
done
echo "实验环境已就绪。"
