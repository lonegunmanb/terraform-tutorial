# 恭喜完成！

你已经掌握了 Terraform 原生测试框架的核心能力：

- **plan 模式（单元测试）**：使用 command = plan 快速验证配置逻辑，无需创建资源
- **apply 模式（集成测试）**：创建临时资源进行端到端验证，测试后自动销毁
- **变量覆盖**：通过文件级和 run 块级 variables 块参数化测试
- **断言**：使用 assert 块验证资源属性、输出值和标签
- **辅助模块**：通过 module 块加载测试专用模块，创建前置资源或验证结果
- **expect_failures**：测试错误分支，验证 validation 规则正确拒绝非法输入
- **Mock Provider**：无需真实凭据快速测试配置逻辑

## 延伸阅读

- [Terraform 测试语法](https://developer.hashicorp.com/terraform/language/tests)
- [Mock 与 Override](https://developer.hashicorp.com/terraform/language/tests/mocking)
- [terraform test 命令](https://developer.hashicorp.com/terraform/cli/commands/test)
