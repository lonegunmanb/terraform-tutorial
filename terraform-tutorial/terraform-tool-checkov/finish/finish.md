# 恭喜完成！

你已经体验了 Checkov 的核心功能：

## 安全扫描能力

- **S3 加密检查**：确保存储桶开启服务端加密
- **版本控制检查**：确保存储桶开启版本控制防止数据丢失
- **访问日志检查**：确保关键存储桶记录访问日志
- **公共访问阻止**：确保存储桶不被意外公开

## 规则管理

- **选择性扫描**：用 --check 只运行指定规则
- **跳过规则**：用 --skip-check 或内联注释跳过不适用的规则
- **软失败模式**：用 --soft-fail 在初始阶段不阻塞 CI

## 自定义策略

- **YAML 策略**：用声明式 YAML 编写组织内部检查规则
- **外部策略目录**：用 --external-checks-dir 加载自定义策略

## 推荐工作流

```
tflint                       # 1. 代码规范检查
checkov -d .                 # 2. 安全合规扫描
terraform validate           # 3. 语义检查
terraform plan               # 4. 计划变更
```

## 延伸阅读

- [Checkov GitHub](https://github.com/bridgecrewio/checkov)
- [Checkov 文档](https://www.checkov.io/)
- [Checkov 详解（Terraform 模块之道）](https://lonegunmanb.github.io/dao-of-terraform-modules/%E5%B7%A5%E5%85%B7%E9%93%BE/checkov.html)
- [AWS 相关规则列表](https://www.checkov.io/5.Policy%20Index/terraform.html)
- [自定义策略指南](https://www.checkov.io/3.Custom%20Policies/YAML%20Custom%20Policies.html)
