# 实验完成

恭喜！你完成了"三层 Web 应用架构——从单体到状态隔离"的全部五个步骤。

## 你做了什么

从一个近 450 行的单体 main.tf 出发，经历代码重构和状态拆分两个阶段——全程零销毁、零重建：

| 步骤 | 做了什么 | 搬迁的资源 |
|------|---------|----------|
| step1 | 部署单体大模块 | — |
| step2 | 提取网络层 + Web 层 | 17 个资源 → module.networking + module.web |
| step3 | 提取数据层 + 存储层 | 6 个资源 → module.data + module.storage |
| step4 | 提取安全层 + 内置防护 | 6 个资源 → module.security + validation/precondition/postcondition |
| step5 | 状态隔离 | 1 个 state → 5 个独立 state（Terragrunt + removed 块）|

24 个 moved 块完成代码重构，5 组 removed 块完成状态拆分。

## 核心原则

- **按层拆分**：networking / web / data / storage / security，每个模块对应一个架构关注点
- **moved 块重构**：资源地址迁移不影响底层基础设施，生产环境可安全执行
- **removed 块拆分**：从统一状态中释放资源到独立状态，不销毁基础设施
- **Terragrunt 编排**：dependency + inputs 声明式连接层间依赖，run-all 按拓扑排序批量执行
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
