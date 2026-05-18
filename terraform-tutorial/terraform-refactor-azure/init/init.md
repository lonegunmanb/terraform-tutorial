# Terraform 代码重构（Azure 版）

在这个实验中，你将学习如何使用 Terraform 的三种重构配置块——import、removed、moved——安全地重组代码结构，而不销毁任何真实基础设施。

资源类型采用 **Azure Storage Account**（与 AWS 版的 S3 桶一一对应），底层 Azure 由 [miniblue](https://github.com/lonegunmanb/miniblue) 在本地模拟，所有操作不需要真实的 Azure 订阅。

你将通过以下四个步骤掌握重构技能：

1. **import** — 将已有的 Storage Account 纳入 Terraform 管理
2. **removed** — 从 Terraform 管理中移除 Storage Account，但保留实际资源
3. **moved（重命名）** — 给资源起一个更好的名字，不销毁不重建
4. **moved（提取模块）** — 将根模块中的资源提取到子模块中

> 💡 本实验使用 miniblue 模拟 Azure ARM 控制平面与 Storage 数据平面，所有操作都在本地完成，无需真实 Azure 订阅。你将使用 `azlocal` 命令来观察实际的 Storage Account 状态。
