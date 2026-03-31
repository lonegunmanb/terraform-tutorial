# 第一步：理解模块结构

查看项目目录结构：

```bash
cd /root/workspace
tree
```

你会看到：

```
.
├── docker-compose.yml
├── main.tf                    ← 根模块（调用方）
└── modules/
    └── s3-bucket/
        ├── main.tf            ← 模块的资源定义
        ├── outputs.tf         ← 模块的输出值
        └── variables.tf       ← 模块的输入参数
```

查看模块的输入参数：

```bash
cat modules/s3-bucket/variables.tf
```

注意 `environment` 变量有 `validation` 块——只允许 `dev`、`staging`、`prod` 三个值。

查看模块的资源定义：

```bash
cat modules/s3-bucket/main.tf
```

模块内部使用 `var.bucket_name` 和 `var.tags` 来创建 S3 存储桶。

查看模块的输出：

```bash
cat modules/s3-bucket/outputs.tf
```

模块通过 `output` 向调用方暴露 `bucket_id` 和 `bucket_arn`。
