# 实验完成

恭喜！你完成了"三层 Web 应用架构——从单体到模块化"的全部四个步骤。

## 你做了什么

从一个近 500 行的单体 main.tf 出发，把三层架构的 30+ 个资源一步步重构为模块化基础设施：

| 步骤 | 做了什么 | 解决的问题 |
|------|---------|----------|
| step1 | 观察单体大模块 | 看清网络/Web/数据/存储/安全混在一起的代价 |
| step2 | 按架构层级拆分五个模块 | 职责分离，权限边界清晰 |
| step3 | 网络层引入 terraform-aws-modules/vpc | 社区验证的 VPC 模块替代手写资源 |
| step4 | 内置防护 + 版本固定 | CIDR 校验、子网数检查、计费模式保证 |

## 核心原则

- **按层拆分**：networking / web / data / storage / security，每个模块对应一个架构关注点
- **可组合**：networking 输出 vpc_id 和 subnet_ids → web 模块消费 → security 模块收集所有 ARN
- **内置防护**：validation → precondition → postcondition，三层递进拦截错误
- **版本固定**：required_version + required_providers + .terraform.lock.hcl 缺一不可

## 三层架构的完整生产版

本实验搭建了三层架构的核心骨架。完整的生产环境还需要：

| 补充项 | 作用 | 对应模块 |
|--------|------|---------|
| NAT Gateway | 私有子网实例出网 | networking |
| Auto Scaling Group | 弹性计算，按负载扩缩容 | 新增 compute 模块 |
| RDS Multi-AZ | 关系型数据库，主从自动切换 | data |
| ElastiCache | Redis 内存缓存，减轻数据库压力 | data |
| CloudFront + WAF | CDN 加速 + Web 应用防火墙 | 新增 cdn 模块 |
| Route 53 | DNS 域名解析与流量路由 | 新增 dns 模块 |
| KMS | 数据加密密钥管理 | security |

这些服务只是增加新模块或扩展现有模块——拆分和组合的方式不变。MiniStack 支持以上所有服务。

## 生产化的下一步

回到[生产级清单](https://lonegunman-terraform-tutorial.github.io/terraform-tutorial/terraform-production-ready-code.html)，对照检查还有哪些事项需要补充。
