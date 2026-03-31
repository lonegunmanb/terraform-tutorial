# Terraform 模块化实践

在这个实验中，你将学习如何编写和使用 Terraform 模块。

工作目录中已经准备好了：
- 一个 **S3 存储桶模块** (`modules/s3-bucket/`)，包含 `variables.tf`、`main.tf`、`outputs.tf`
- 一个**根模块** (`main.tf`)，调用了上述模块

你的任务是理解模块的工作方式，然后通过复用模块来创建多个存储桶。

> 💡 模块是 Terraform 的核心复用机制，类似于编程语言中的函数。
