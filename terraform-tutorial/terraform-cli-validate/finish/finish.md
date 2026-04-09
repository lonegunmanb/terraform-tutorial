# 恭喜完成 terraform validate 实战练习！

## 知识总结

| 功能 | 命令 / 参数 | 核心场景 |
|------|------------|---------|
| 验证配置语法 | terraform validate | 编辑器保存后检查 |
| 机器可读输出 | terraform validate -json | CI 集成、编辑器插件 |
| 无颜色输出 | terraform validate -no-color | 日志系统采集 |
| 离线初始化 | terraform init -backend=false | 只下载插件不连 backend |

## validate 能检测的错误

- 属性名拼写错误（如 buckeet → bucket）
- 类型不匹配（如 number 赋给 string 类型变量）
- 引用不存在的变量或资源
- 必填属性或块缺失
- 块结构不合法

## validate 不能检测的问题

- 远端资源是否存在
- 变量值是否满足业务约束
- provider API 是否可达
- state 与远端是否一致

这些需要 terraform plan 或 terraform apply 来发现。

## CI 推荐流程

```
terraform init -backend=false
terraform fmt -check -recursive
terraform validate          # 快速拦截语法错误
terraform plan -input=false  # 完整的运行时验证
```
