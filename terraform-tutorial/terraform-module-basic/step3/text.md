# 第二步：创建并调用子模块

在这一步中，你将学习如何创建子模块、在根模块中调用它，以及理解模块的作用域隔离。

## 查看预置的模块代码

```bash
cd /root/workspace/step3
```

这个目录已经为你准备了一个完整的模块调用示例。先看看目录结构：

```bash
find . -name '*.tf' | sort
```

你会看到：

```
./main.tf
./modules/s3-bucket/main.tf
./modules/s3-bucket/outputs.tf
./modules/s3-bucket/variables.tf
```

## 查看子模块的代码

先看子模块的三个文件——这是一个标准结构的 S3 桶模块：

```bash
echo "=== variables.tf ==="
cat modules/s3-bucket/variables.tf

echo "=== main.tf ==="
cat modules/s3-bucket/main.tf

echo "=== outputs.tf ==="
cat modules/s3-bucket/outputs.tf
```

模块的接口非常清晰：
- **输入**：bucket_name（必填）和 tags（可选）
- **资源**：创建一个 aws_s3_bucket
- **输出**：暴露 bucket_id 和 bucket_arn

## 查看根模块如何调用子模块

```bash
cat main.tf
```

注意根模块中的 module 块：

```hcl
module "data_bucket" {
  source      = "./modules/s3-bucket"
  bucket_name = "my-app-data"
  tags = { ... }
}
```

关键点：
- source 指定模块路径（这里是本地路径）
- 其余参数对应模块 variables.tf 中定义的变量
- 通过 module.data_bucket.bucket_id 引用模块输出

同一个模块代码被调用了两次（data_bucket 和 logs_bucket），传入不同参数创建不同的桶——这就是模块复用。

## 初始化并执行

```bash
terraform init
```

注意 init 输出中的 "Initializing modules..." 提示——Terraform 正在加载本地模块。

```bash
terraform plan
```

观察 plan 输出，注意资源地址的格式：

- module.data_bucket.aws_s3_bucket.this
- module.logs_bucket.aws_s3_bucket.this

资源地址前面多了 module.<模块名> 前缀，表示该资源属于某个子模块。对比上一步中直接定义的 aws_s3_bucket.app_data，区别一目了然。

```bash
terraform apply -auto-approve
```

## 验证模块的作用域隔离

模块内部和外部是隔离的。你只能通过模块声明的 output 访问模块内部的资源属性：

```bash
terraform output data_bucket_id
terraform output data_bucket_arn
```

查看状态中的资源地址：

```bash
terraform state list
```

输出类似：

```
module.data_bucket.aws_s3_bucket.this
module.logs_bucket.aws_s3_bucket.this
```

验证桶已创建：

```bash
awslocal s3 ls
```

## 体验嵌套模块

子模块内部可以继续调用其他模块，形成嵌套结构。创建一个 app 模块，它内部调用 s3-bucket 模块：

```bash
mkdir -p modules/app
```

```bash
cat > modules/app/variables.tf <<'EOF'
variable "app_name" {
  type        = string
  description = "应用名称，用作资源命名前缀"
}
EOF
```

```bash
cat > modules/app/main.tf <<'EOF'
# app 模块内部调用 s3-bucket 模块 —— 形成嵌套
module "storage" {
  source      = "../s3-bucket"
  bucket_name = "${var.app_name}-storage"
  tags = {
    App = var.app_name
  }
}

module "cache" {
  source      = "../s3-bucket"
  bucket_name = "${var.app_name}-cache"
  tags = {
    App = var.app_name
  }
}
EOF
```

```bash
cat > modules/app/outputs.tf <<'EOF'
output "storage_bucket_id" {
  value = module.storage.bucket_id
}

output "cache_bucket_id" {
  value = module.cache.bucket_id
}
EOF
```

在根模块中调用 app 模块：

```bash
cat >> main.tf <<'EOF'

# 调用 app 模块 —— 它内部会嵌套调用 s3-bucket 模块
module "my_app" {
  source   = "./modules/app"
  app_name = "demo"
}

output "app_storage_id" {
  value = module.my_app.storage_bucket_id
}

output "app_cache_id" {
  value = module.my_app.cache_bucket_id
}
EOF
```

重新初始化并执行：

```bash
terraform init
terraform apply -auto-approve
```

查看状态中的资源地址，注意嵌套层级：

```bash
terraform state list
```

输出类似：

```
module.data_bucket.aws_s3_bucket.this
module.logs_bucket.aws_s3_bucket.this
module.my_app.module.cache.aws_s3_bucket.this
module.my_app.module.storage.aws_s3_bucket.this
```

最后两个资源的地址是 module.my_app.module.cache... —— 两层 module. 前缀反映了嵌套调用链：根模块 -> app 模块 -> s3-bucket 模块。

验证所有桶都已创建：

```bash
awslocal s3 ls
```

你应该看到 4 个桶：my-app-data、my-app-logs、demo-storage、demo-cache。

## 清理

```bash
terraform destroy -auto-approve
```

## 关键点

- 通过 module 块调用子模块，source 指定模块路径
- 调用方通过参数传入值，通过 module.<名称>.<输出> 获取模块输出
- 模块内外作用域隔离——内部资源只能通过 output 暴露
- 同一个模块代码可以被多次调用，创建独立的资源实例
- 子模块可以嵌套调用其他模块，资源地址会体现嵌套层级
- 添加新模块后需要重新执行 terraform init

完成后继续下一步。
