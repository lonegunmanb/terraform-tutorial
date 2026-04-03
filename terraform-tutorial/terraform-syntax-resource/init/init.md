# Terraform 资源

在这个实验中，你将通过三个仿真应用场景，学习 Terraform 资源（resource）的核心用法。

资源是 Terraform 最重要的组成部分——每个 resource 块声明一个你希望创建的基础设施对象。你将通过以下三个步骤掌握资源的关键知识点：

1. **资源基础** — 创建 S3 存储桶和对象，学习资源语法、属性引用和依赖关系
2. **count 与 for_each** — 批量创建 SQS 队列和 DynamoDB 表，掌握多实例资源的两种方式
3. **lifecycle、dynamic 和 provisioner** — 使用生命周期管理、动态块和本地执行器

> 💡 本实验使用 LocalStack 模拟 AWS 服务，所有操作都在本地完成，无需真实 AWS 账号。
