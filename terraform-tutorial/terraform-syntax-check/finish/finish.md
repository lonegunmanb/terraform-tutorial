# 🎉 实验完成！

你已经掌握了 Terraform check 块的核心知识：

## 核心概念回顾

- **check 块** — `check "名称" { ... }` 定义独立于资源生命周期的验证逻辑
- **assert 断言** — 失败时产生**警告**而非错误，不阻塞 Terraform 操作
- **有限作用域数据源** — check 内嵌的 data 块，只能在 check 块内引用，错误降级为警告
- **depends_on** — 让有限作用域数据源依赖于相关资源，避免资源创建前的无意义警告
- **与 postcondition 的区别** — postcondition 失败会报错并阻止操作；check 失败只是提醒

## check vs 其他验证方式

| 场景 | 推荐方式 |
|------|----------|
| 校验用户输入格式 | variable validation |
| 资源创建前验证前提条件 | precondition |
| 确保资源创建后的状态正确 | postcondition |
| 监测基础设施整体健康状态 | **check** |
| 不希望验证失败阻塞操作 | **check** |

## 下一步

返回教程主页，继续学习下一个章节。
