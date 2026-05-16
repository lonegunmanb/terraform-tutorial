# 生产就绪代码（Azure / miniblue 版）

本实验使用 miniblue 在本地模拟 Azure API，带你把一个三层 Web 应用的 Terraform 配置从单体文件逐步重构为模块化结构，并进一步拆分为多份独立 state。

你会练习：

- 用 moved 块在不销毁资源的前提下移动资源地址
- 把网络、安全、虚拟机、存储和 DNS 拆成职责清晰的小模块
- 用 validation、precondition、postcondition 增加内置防护
- 用 Terragrunt 和 removed 块完成状态隔离
