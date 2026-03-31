# 第三步：复用模块

模块的威力在于**复用**。现在用同一个模块创建第二个存储桶。

打开 `main.tf`，将 `app_logs` 模块和其 output 的注释取消（删除 `#`）：

```hcl
module "app_logs" {
  source = "./modules/s3-bucket"

  bucket_name = "my-app-logs"
  environment = "dev"

  tags = {
    Team = "platform"
  }
}

output "logs_bucket_id" {
  value = module.app_logs.bucket_id
}
```

再次初始化（新的 module 调用需要 init）并应用：

```bash
terraform init
terraform plan
```

注意 plan 只显示**新增 1 个资源**——已有的 `app_data` 存储桶不受影响。

```bash
terraform apply -auto-approve
aws --endpoint-url=http://localhost:4566 s3 ls
```

你应该看到两个存储桶，都由同一个模块创建，但配置不同。

🎉 你发现了模块化的核心价值：**写一次，用多次，每次可以传入不同的参数**。
