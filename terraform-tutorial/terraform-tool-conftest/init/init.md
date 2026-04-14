# Conftest 实战

通过本节实验，你将体验 Conftest 如何基于 OPA Rego 策略对 Terraform Plan 输出进行合规检查。

## 实验场景

工作目录中有一个 Terraform 项目，创建两个 S3 存储桶。同时准备了三条 Rego 策略：

- 所有 S3 桶必须开启版本控制
- 所有 S3 桶必须开启服务端加密
- 所有 S3 桶必须包含 Environment 和 ManagedBy 标签

你将生成 Terraform Plan 的 JSON 输出，然后用 Conftest 逐步应用这些策略，发现违规配置并修复。

## 学习内容

| 内容 | 说明 |
|------|------|
| Plan JSON 生成 | terraform plan + terraform show -json |
| Rego 策略理解 | 理解 deny 规则和 input 数据结构 |
| Conftest 运行 | conftest test 基本用法 |
| 输出格式 | table/json 等输出格式 |
| 策略例外 | 跳过特定规则 |

点击右侧箭头开始实验。
