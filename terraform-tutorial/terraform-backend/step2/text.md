# 第二步：配置 S3 后端

现在我们将状态从本地迁移到 S3 远程后端，并亲手体验**状态锁定**的作用。

## 确认当前状态

step2 目录已经预先执行了 terraform apply，有一个使用本地后端的 S3 存储桶资源：

```bash
cd /root/workspace/step2
terraform state list
```

你应该看到 aws_s3_bucket.demo——当前状态存储在本地 terraform.tfstate 文件中。

## 确认基础设施就绪

实验环境已预先创建了存放状态文件的 S3 桶和用于状态锁定的 DynamoDB 表：

```bash
awslocal s3 ls
awslocal dynamodb list-tables
```

你应该能看到 terraform-state-bucket（存放状态）和 terraform-locks 表（用于锁定）。

## 修改配置，添加 S3 后端

用以下命令替换 main.tf，添加 S3 后端配置（含 DynamoDB 锁定）：

```bash
cat > main.tf <<'EOF'
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }

  backend "s3" {
    bucket         = "terraform-state-bucket"
    key            = "demo/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"

    access_key                  = "test"
    secret_key                  = "test"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    use_path_style              = true
    skip_s3_checksum            = true
    skip_region_validation      = true

    endpoints = {
      s3       = "http://localhost:4566"
      dynamodb = "http://localhost:4566"
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

resource "aws_s3_bucket" "demo" {
  bucket = "backend-demo-bucket"
  tags = {
    Name      = "Demo Bucket"
    ManagedBy = "Terraform"
  }
}

output "bucket_name" {
  value = aws_s3_bucket.demo.bucket
}
EOF
```

注意 backend "s3" 块中的关键配置：
- bucket / key 指定状态文件的存储位置
- dynamodb_table 指定用于状态锁定的 DynamoDB 表

## 迁移状态到 S3

运行 terraform init，Terraform 会检测到后端配置变更：

```bash
terraform init
```

当提示 Do you want to migrate all workspaces to "s3"? 时，输入 yes 并回车。

## 验证迁移结果

确认状态已存储到 S3：

```bash
awslocal s3 ls s3://terraform-state-bucket/demo/
```

确认 Terraform 仍能正常管理资源：

```bash
terraform plan
```

输出应显示 No changes。

## 体验状态锁定

状态锁定的作用是：当一个 Terraform 操作正在执行时，其他操作无法同时修改状态，避免冲突和数据损坏。

我们用一个 time_sleep 资源让 terraform apply 阻塞 30 秒，在这段时间内观察锁的存在。先添加 time_sleep 资源：

```bash
cat >> main.tf <<'EOF'

resource "time_sleep" "lock_demo" {
  create_duration = "30s"
}
EOF
```

环境中预置了一个演示脚本 show-lock.sh，它会自动完成以下操作：

1. 后台启动 terraform apply
2. 轮询等待 Terraform 获取锁
3. 查询 DynamoDB 锁表并展示锁的详细信息（LockID、Operation、Who、Created）
4. 尝试并发执行 terraform plan——你会看到锁冲突错误
5. 等待 apply 完成，确认锁被自动释放

运行脚本：

```bash
bash ./show-lock.sh
```

观察输出，你会看到以下关键信息：

**DynamoDB 锁表内容** — 锁记录中包含：
- LockID：状态文件路径（terraform-state-bucket/demo/terraform.tfstate）
- Info：JSON 数据，记录了谁持有锁、执行的操作类型、锁的创建时间

**锁冲突错误** — 尝试并发 terraform plan 时会报错：

```
Error: Error acquiring the state lock

Terraform acquires a state lock to protect the state from being
written by multiple users at the same time.

Lock Info:
  ID:        ...
  Path:      terraform-state-bucket/demo/terraform.tfstate
  Operation: OperationTypeApply
```

这正是状态锁定在保护你——它阻止了并发操作，确保同一时间只有一个 Terraform 进程能修改状态。

**锁释放** — apply 完成后锁表记录数变为 0，说明 Terraform 自动释放了锁。

## 清理 time_sleep

time_sleep 仅用于演示锁定，现在将它从配置中移除：

```bash
sed -i '/^resource "time_sleep"/,/^}/d' main.tf
terraform apply -auto-approve
```

Terraform 会销毁 time_sleep 资源，状态中只剩下 S3 存储桶。

确认状态干净：

```bash
terraform plan
```

输出应显示 No changes。

## 关键点

- S3 后端将状态存储在远程 S3 存储桶中，团队成员可以共享
- dynamodb_table 参数启用基于 DynamoDB 的状态锁定，防止并发操作冲突
- Terraform 在执行 apply/destroy 等修改操作时自动获取锁，完成后自动释放
- 持有锁期间，其他 Terraform 操作会立即报错，避免状态被破坏
