# mapotf 实战：为第三方模块定制 ignore_changes

通过本节实验，你将亲手体验一个真实的痛点场景：第三方模块创建的资源被外部策略修改导致 drift，然后用 mapotf 优雅地解决它。

## 实验场景

- 使用社区 VPC 模块（terraform-aws-modules/vpc/aws v5.16.0）部署 VPC
- LocalStack 中有一个"合规策略"后台进程，会自动给所有 VPC 打上 compliance-team 和 auto-tagged-at 标签
- 每次 terraform plan 都会报告标签漂移，因为模块内部没有 ignore_changes
- 你不能修改模块源码（否则无法升级），Terraform 也不支持从外部传入 ignore_changes
- 解决方案：用 mapotf 动态修改下载后的模块代码

## 学习内容

| 步骤 | 内容 |
|------|------|
| 步骤 1 | 部署 VPC 模块，观察自动标签导致的 drift |
| 步骤 2 | 编写 mapotf 规则，用 transform + apply 消除漂移 |

点击右侧箭头开始实验。
