# moved — 提取到模块

随着代码规模增长，你可能需要将根模块中零散的资源提取到子模块中。moved 块可以让这种重构安全进行——不销毁任何资源。

## 场景

进入 step4 目录，查看当前状态：

```
cd /root/workspace/step4
terraform state list
```

你应该看到两个资源直接位于根模块中：aws_s3_bucket.user_uploads 和 aws_s3_bucket.user_backups。

确认桶存在：

```
awslocal s3 ls | grep modular
```

## 目标

我们要把这两个资源提取到 modules/s3-bucket 子模块中。目标架构：

```
根模块
├── module "uploads"  → modules/s3-bucket  (管理 modular-user-uploads)
└── module "backups"  → modules/s3-bucket  (管理 modular-user-backups)
```

modules/s3-bucket 子模块已经准备好了，先看一下它的接口：

```
cat /root/workspace/modules/s3-bucket/variables.tf
cat /root/workspace/modules/s3-bucket/outputs.tf
```

## 重构代码

编辑 main.tf，将两个 resource 块替换为 module 调用，并添加 moved 块告诉 Terraform 资源的新地址：

```
cat > main.tf << 'EOF'
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = "test"
  secret_key = "test"

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    s3  = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}

module "uploads" {
  source      = "../modules/s3-bucket"
  bucket_name = "modular-user-uploads"
  tags = {
    Purpose = "uploads"
  }
}

module "backups" {
  source      = "../modules/s3-bucket"
  bucket_name = "modular-user-backups"
  tags = {
    Purpose = "backups"
  }
}

moved {
  from = aws_s3_bucket.user_uploads
  to   = module.uploads.aws_s3_bucket.this
}

moved {
  from = aws_s3_bucket.user_backups
  to   = module.backups.aws_s3_bucket.this
}
EOF
```

注意 moved 块中的 to 地址是 module.uploads.aws_s3_bucket.this——因为子模块内部的资源名称是 this（查看 modules/s3-bucket/main.tf 就能确认），所以完整路径是 module.<调用名>.aws_s3_bucket.this。

## 重新初始化

因为添加了新的 module 调用，需要重新 init：

```
terraform init
```

## 查看计划

```
terraform plan
```

你应该看到两条移动记录，没有任何销毁或创建：

```
# aws_s3_bucket.user_uploads has moved to module.uploads.aws_s3_bucket.this
# aws_s3_bucket.user_backups has moved to module.backups.aws_s3_bucket.this
```

## 执行

```
terraform apply -auto-approve
```

## 验证

检查新的资源地址：

```
terraform state list
```

资源地址已经变成 module.uploads.aws_s3_bucket.this 和 module.backups.aws_s3_bucket.this。

确认 S3 桶完全没有变化：

```
awslocal s3 ls | grep modular
```

桶还是原来的桶，内容未受影响。

最后确认 plan 干净：

```
terraform plan
```

No changes——重构完成，零停机、零风险。

> 小结：moved 块让你可以自由地重组代码结构——重命名、提取模块、拆分模块——而不必担心 Terraform 误删真实的基础设施。记住：移除 moved 块是破坏性变更，对于公开模块建议永久保留。
