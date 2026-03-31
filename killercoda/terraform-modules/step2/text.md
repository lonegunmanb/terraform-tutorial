# 第二步：使用模块创建资源

查看根模块如何调用 s3-bucket 模块：

```bash
cat main.tf
```

关键部分：

```hcl
module "app_data" {
  source      = "./modules/s3-bucket"
  bucket_name = "my-app-data"
  environment = "dev"
  tags        = { Team = "backend" }
}
```

- `source` 指向模块所在的目录
- 其余参数对应模块 `variables.tf` 中定义的变量
- `output` 通过 `module.app_data.bucket_id` 引用模块输出

初始化并执行：

```bash
terraform init
terraform plan
```

确认 plan 显示将创建一个 S3 存储桶，然后应用：

```bash
terraform apply -auto-approve
```

验证：

```bash
aws --endpoint-url=http://localhost:4566 s3 ls
```
