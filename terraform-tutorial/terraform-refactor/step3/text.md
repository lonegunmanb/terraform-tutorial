# moved — 重命名资源

当你需要给资源起一个更好的名字时，直接修改名称会导致 Terraform 销毁旧资源、创建新资源。moved 块可以告诉 Terraform "这只是改名，不要删除重建"。

## 场景

进入 step3 目录，这里有两个命名不佳的 S3 桶（b1 和 b2）：

```
cd /root/workspace/step3
terraform state list
```

你应该看到 aws_s3_bucket.b1 和 aws_s3_bucket.b2。

看看它们对应的实际桶名：

```
terraform state show aws_s3_bucket.b1 | grep bucket
terraform state show aws_s3_bucket.b2 | grep bucket
```

b1 是 moved-demo-uploads，b2 是 moved-demo-archives。名字 b1、b2 毫无含义，我们要重构为更清晰的名称。

## 先看看直接改名会怎样

假设我们直接把 b1 改成 uploads——临时修改看 plan（不要 apply）：

```
sed -i 's/"b1"/"uploads"/' main.tf
terraform plan
```

Terraform 会显示一个 destroy（b1）加一个 create（uploads）——这意味着 S3 桶会被删除再重建！对于生产环境的存储桶来说，这是灾难。

恢复原始文件：

```
sed -i 's/"uploads"/"b1"/' main.tf
```

## 使用 moved 块安全重命名

编辑 main.tf，同时修改资源名称并添加 moved 块：

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

resource "aws_s3_bucket" "uploads" {
  bucket = "moved-demo-uploads"
}

resource "aws_s3_bucket" "archives" {
  bucket = "moved-demo-archives"
}

moved {
  from = aws_s3_bucket.b1
  to   = aws_s3_bucket.uploads
}

moved {
  from = aws_s3_bucket.b2
  to   = aws_s3_bucket.archives
}
EOF
```

## 查看计划

```
terraform plan
```

这次输出完全不同——没有 destroy，没有 create：

```
# aws_s3_bucket.b1 has moved to aws_s3_bucket.uploads
# aws_s3_bucket.b2 has moved to aws_s3_bucket.archives
```

Terraform 理解了：这只是换了名字，同一个资源。

## 执行

```
terraform apply -auto-approve
```

## 验证

检查状态文件中的新地址：

```
terraform state list
```

资源地址已经变成 aws_s3_bucket.uploads 和 aws_s3_bucket.archives。

确认 S3 桶完全没变：

```
awslocal s3 ls
```

桶名和内容完全一致——只是 Terraform 里的"身份证号"更新了。

再跑一次 plan 确认干净：

```
terraform plan
```

输出应该是 No changes。

> 提示：moved 块对资源的所有实例生效——如果资源使用了 count 或 for_each，所有实例会自动跟随移动。同样地，重命名模块调用也可以用 moved 块实现，例如 from = module.old_name, to = module.new_name。
